#!/bin/bash

set -euo pipefail

# DESCRIPTION:
# This script sets up observability for an Azure IoT Operations instance by
# provisioning necessary Azure resources and configuring the instance to use
# them. It performs the following steps:
# 1. Creates or retrieves an Azure Monitor Workspace for cluster metrics.
# 2. Creates or retrieves a Grafana instance for visualizing cluster metrics.
# 3. Creates or retrieves a Log Analytics Workspace for container logs.
# 4. Installs Azure Monitor Metrics and Containers extensions on the
#    Kubernetes cluster.
# 5. Deploys an OpenTelemetry collector to the cluster to collect and export
#    metrics.
# 6. Configures Azure IoT Operations to use the OpenTelemetry collector for
#    metrics.
#
#
# PARAMETERS:
# - Environment:
#   - RESOURCE_GROUP: REQUIRED
#     Azure Resource Group to provision the observability resources in. Must
#     already exist. Must use the same resource group as the target Azure
#     IoT Operations instance.
#   - CLUSTER_NAME: REQUIRED
#     Name of the Kubernetes cluster where Azure IoT Operations is deployed. 
#   - INSTANCE_NAME: REQUIRED
#     Name of the Azure IoT Operations instance to configure.
#   - WORKSPACE_NAME: REQUIRED
#     Name of the Azure Monitor Workspace to create/use for cluster metrics.
#   - GRAFANA_NAME: REQUIRED
#     Name of the Grafana instance to create/use for cluster metrics.
#   - LOGS_WORKSPACE_NAME: REQUIRED
#     Name of the Log Analytics Workspace to create/use for container logs.
#   - LOCATION: OPTIONAL
#     Azure region to provision resources in. Required if any resources need 
#     to be created.

usage() {
  cat <<'EOF'
Usage:
  setup-monitoring.sh

Required environment variables:
  RESOURCE_GROUP         Azure resource group for AIO and monitoring resources
  CLUSTER_NAME           Connected cluster name where AIO runs
  INSTANCE_NAME          Azure IoT Operations instance name
  WORKSPACE_NAME         Azure Monitor Workspace name
  GRAFANA_NAME           Azure Managed Grafana instance name
  LOGS_WORKSPACE_NAME    Log Analytics Workspace name

Optional environment variables:
  LOCATION               Azure region (required only when resources must be created)
  SKIP_CONFIRMATION=1    Skip interactive disruptive-action confirmation prompt

Examples:
  export RESOURCE_GROUP=rg-aio
  export CLUSTER_NAME=my-connected-cluster
  export INSTANCE_NAME=my-aio
  export WORKSPACE_NAME=my-amw
  export GRAFANA_NAME=my-grafana
  export LOGS_WORKSPACE_NAME=my-law
  export LOCATION=westus2
  ./setup-monitoring.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

confirm_disruptive_actions() {
  if [[ "${SKIP_CONFIRMATION:-0}" == "1" ]]; then
    log "Skipping disruptive-action confirmation because SKIP_CONFIRMATION=1"
    return
  fi

  if [[ ! -t 0 ]]; then
    fail "Interactive confirmation required. Re-run in a terminal or set SKIP_CONFIRMATION=1."
  fi

  cat <<'EOF'
WARNING: This script performs potentially disruptive actions and may interfere with existing monitoring setup.

It can create/update and overwrite settings for:
  - Azure k8s extensions:
      * azuremonitor-metrics
      * azuremonitor-containers
  - Helm release:
      * aio-observability (namespace: azure-iot-operations)
  - Kubernetes ConfigMap:
      * kube-system/ama-metrics-prometheus-config
  - Azure IoT Operations observability configuration via az iot ops upgrade

Recommended: run this script on new installations where AMA-related monitoring extensions and configs are not already in use.
EOF

  local answer=""
  read -r -p "Proceed? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES)
      log "User confirmed disruptive actions"
      ;;
    *)
      fail "Aborted by user"
      ;;
  esac
}

if (( $# > 0 )); then
  fail "This script does not accept positional arguments. Use --help for usage."
fi

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "Required environment variable '$name' is not set"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is not installed or not on PATH"
}

trap 'echo "ERROR: Script failed at line $LINENO" >&2' ERR

log "[0/6] Running preflight checks..."

require_cmd az
require_cmd kubectl
require_cmd helm

require_env RESOURCE_GROUP
require_env CLUSTER_NAME
require_env INSTANCE_NAME
require_env WORKSPACE_NAME
require_env GRAFANA_NAME
require_env LOGS_WORKSPACE_NAME

az account show >/dev/null 2>&1 || fail "Azure CLI is not logged in. Run 'az login' and set the correct subscription before running this script."
kubectl cluster-info >/dev/null 2>&1 || fail "kubectl cannot reach the target cluster. Ensure kubeconfig/context is set correctly."

log "[0/6] Preflight checks passed"

confirm_disruptive_actions

az provider register --namespace Microsoft.AlertsManagement
az provider register --namespace Microsoft.Monitor
az provider register --namespace Microsoft.Dashboard
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights

az extension add --upgrade --name k8s-extension
az extension add --upgrade --name amg

# Create or get Azure Monitor Workspace
log "[1/6] Creating/getting Azure Monitor Workspace..."
if AZURE_MONITOR_WORKSPACE_ID=$(az monitor account show --name "$WORKSPACE_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv 2>/dev/null); then
  log "Azure Monitor Workspace already exists"
else
  require_env LOCATION
  AZURE_MONITOR_WORKSPACE_ID=$(az monitor account create --name "$WORKSPACE_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --query id -o tsv)
fi
log "Azure Monitor Workspace ID: $AZURE_MONITOR_WORKSPACE_ID"

# Create or get Grafana (skip role assignments to avoid AAD Conditional Access issues)
log "[2/6] Creating/getting Grafana..."
if GRAFANA_ID=$(az grafana show --name "$GRAFANA_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv 2>/dev/null); then
  log "Grafana already exists"
else
  require_env LOCATION
  GRAFANA_ID=$(az grafana create --name "$GRAFANA_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --query id -o tsv)
fi
log "Grafana ID: $GRAFANA_ID"

# Create or get Log Analytics Workspace
log "[3/6] Creating/getting Log Analytics Workspace..."
if LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show -g "$RESOURCE_GROUP" -n "$LOGS_WORKSPACE_NAME" --query id -o tsv 2>/dev/null); then
  log "Log Analytics Workspace already exists"
else
  require_env LOCATION
  LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace create -g "$RESOURCE_GROUP" -n "$LOGS_WORKSPACE_NAME" -l "$LOCATION" --query id -o tsv)
fi
log "Log Analytics Workspace ID: $LOG_ANALYTICS_WORKSPACE_ID"

# Create or update Azure Monitor Metrics extension
log "[4/6] Creating/updating Azure Monitor Metrics extension..."
if az k8s-extension show --name azuremonitor-metrics --cluster-name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters &>/dev/null; then
  az k8s-extension update --name azuremonitor-metrics \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type connectedClusters \
    --configuration-settings azure-monitor-workspace-resource-id="$AZURE_MONITOR_WORKSPACE_ID" grafana-resource-id="$GRAFANA_ID"
else
  az k8s-extension create --name azuremonitor-metrics \
        --cluster-name "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --cluster-type connectedClusters \
        --extension-type Microsoft.AzureMonitor.Containers.Metrics \
        --configuration-settings azure-monitor-workspace-resource-id="$AZURE_MONITOR_WORKSPACE_ID" grafana-resource-id="$GRAFANA_ID"
fi

# Create or update Azure Monitor Containers extension
log "[4/6] Creating/updating Azure Monitor Containers extension..."
if az k8s-extension show --name azuremonitor-containers --cluster-name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters &>/dev/null; then
  az k8s-extension update --name azuremonitor-containers \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type connectedClusters \
    --configuration-settings logAnalyticsWorkspaceResourceID="$LOG_ANALYTICS_WORKSPACE_ID"
else
  az k8s-extension create --name azuremonitor-containers \
        --cluster-name "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --cluster-type connectedClusters \
        --extension-type Microsoft.AzureMonitor.Containers \
        --configuration-settings logAnalyticsWorkspaceResourceID="$LOG_ANALYTICS_WORKSPACE_ID"
fi

# Create namespace and install OpenTelemetry collector
log "[5/6] Setting up OpenTelemetry collector..."
kubectl get namespace azure-iot-operations >/dev/null 2>&1 || kubectl create namespace azure-iot-operations
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo update

helm upgrade --install aio-observability open-telemetry/opentelemetry-collector \
  --namespace azure-iot-operations \
  --wait \
  --timeout 10m \
  -f - <<'EOF'
mode: deployment
fullnameOverride: aio-otel-collector
image:
  repository: otel/opentelemetry-collector
  tag: 0.143.0

config:
  processors:
    memory_limiter:
      limit_percentage: 80
      spike_limit_percentage: 10
      check_interval: 60s

  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: ":4317"
        http:
          endpoint: ":4318"

  exporters:
    prometheus:
      endpoint: ":8889"
      resource_to_telemetry_conversion:
        enabled: true
      add_metric_suffixes: false

  service:
    extensions:
      - health_check

    telemetry:
      metrics:
        level: none

    pipelines:
      metrics:
        receivers:
          - otlp
        exporters:
          - prometheus

resources:
  limits:
    cpu: "100m"
    memory: "512Mi"

ports:
  metrics:
    enabled: true
    containerPort: 8889
    servicePort: 8889
    protocol: TCP
EOF

log "[5/6] Collector setup complete"

# Apply Prometheus scrape config
log "[5/6] Applying Prometheus scrape config..."
kubectl apply -f - <<'EOF'
apiVersion: v1
data:
  prometheus-config: |2-
    scrape_configs:
      - job_name: otel
        scrape_interval: 1m
        static_configs:
          - targets:
            - aio-otel-collector.azure-iot-operations.svc.cluster.local:8889
      - job_name: aio-annotated-pod-metrics
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - action: drop
            regex: true
            source_labels:
              - __meta_kubernetes_pod_container_init
          - action: keep
            regex: true
            source_labels:
              - __meta_kubernetes_pod_annotation_prometheus_io_scrape
          - action: replace
            regex: ([^:]+)(?::\\d+)?;(\\d+)
            replacement: $1:$2
            source_labels:
              - __address__
              - __meta_kubernetes_pod_annotation_prometheus_io_port
            target_label: __address__
          - action: replace
            source_labels:
              - __meta_kubernetes_namespace
            target_label: kubernetes_namespace
          - action: keep
            regex: 'azure-iot-operations'
            source_labels:
              - kubernetes_namespace
        scrape_interval: 1m
kind: ConfigMap
metadata:
  name: ama-metrics-prometheus-config
  namespace: kube-system
EOF

# Upgrade Azure IoT Operations to use the OpenTelemetry collector
log "[6/6] Configuring Azure IoT Operations observability..."
az iot ops upgrade \
  --resource-group "$RESOURCE_GROUP" \
  -n "$INSTANCE_NAME" \
  --ops-config observability.metrics.openTelemetryCollectorAddress=aio-otel-collector.azure-iot-operations.svc.cluster.local:4317 \
  --ops-config observability.metrics.exportIntervalSeconds=60 \
  --ops-config observability.metrics.enabled=True

log "[6/6] Azure IoT Operations observability configured!"
