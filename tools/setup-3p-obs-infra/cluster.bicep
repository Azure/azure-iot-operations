// This template deploys cluster-specific observability resources for connecting
// the Arc-enabled cluster to the shared Azure Monitor workspace and Log
// Analytics workspace. It is meant to be run against the resource group
// containing the Arc-enabled cluster, though it also creates a few resources in
// the resource group containing the Azure Monitor workspace where required.

@description('Name of the cluster to monitor')
@minLength(1)
param clusterName string

@description('Region where the cluster-connected resources should be created')
param location string = resourceGroup().location

@description('Azure Monitor Resource ID')
param azureMonitorId string

@description('Log Analytics Workspace Resource ID')
param logAnalyticsId string

@description('Azure Monitor Location')
param azureMonitorLocation string = location

@description('Log Analytics Workspace Location')
param logAnalyticsLocation string = location

@description('Interval to scrape metrics from the cluster')
param scrapeInterval string = 'PT1M'

@description('Domain of Azure Monitor logs. Do not change unless using a sovereign cloud')
param amaLogsDomain string = 'opinsights.azure.com'

resource cluster 'Microsoft.Kubernetes/connectedClusters@2023-11-01-preview' existing = {
  name: clusterName
}

// Module for creating Prometheus recording rules. These are created in the
// resource group containing the Azure Monitor workspace.
module recordingRules './cluster-recordingRules.bicep' = {
  name: '${deployment().name}-recordingRules'
  params: {
    location: azureMonitorLocation
    clusterId: cluster.id
    clusterName: clusterName
    azureMonitorId: azureMonitorId
    scrapeInterval: scrapeInterval
  }
}

// Module for setting up data collection on the cluster for both metrics and
// logs. These are created in the cluster's resource group, but must be in the
// region of the respective Azure Monitor and Log Analytics workspaces.
module dataCollectionRules './cluster-dataCollectionRules.bicep' = {
  name: '${deployment().name}-dataCollectionRules'
  params: {
    azureMonitorLocation: azureMonitorLocation
    logAnalyticsLocation: logAnalyticsLocation
    clusterName: clusterName
    logAnalyticsId: logAnalyticsId
    azureMonitorId: azureMonitorId
  }
}

// Create an instance of the metrics extension for Azure Monitor on the cluster.
resource azmonExtension 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'azuremonitor-metrics'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'Microsoft.AzureMonitor.Containers.Metrics'
    configurationSettings: {
      'AzureMonitorMetrics.KubeStateMetrics.MetricsLabelsAllowlist': ''
      'AzureMonitorMetrics.KubeStateMetrics.MetricAnnotationsAllowList': ''
    }
    configurationProtectedSettings: {}
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'kube-system'
      }
    }
  }
  scope: cluster
}

// Create an instance of the container insights extension for Azure Monitor on
// the cluster.
resource containerInsightsExtension 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'azuremonitor-containers'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'Microsoft.AzureMonitor.Containers'
    configurationSettings: {
      logAnalyticsWorkspaceResourceID: logAnalyticsId
      'omsagent.domain': amaLogsDomain
      'amalogs.domain': amaLogsDomain
      'omsagent.useAADAuth': 'true'
      'amalogs.useAADAuth': 'true'
    }
    configurationProtectedSettings: {
      'amalogs.secret.wsid': reference(logAnalyticsId, '2015-03-20').customerId
      'amalogs.secret.key': listKeys(logAnalyticsId, '2015-03-20').primarySharedKey
      'omsagent.secret.wsid': reference(logAnalyticsId, '2015-03-20').customerId
      'omsagent.secret.key': listKeys(logAnalyticsId, '2015-03-20').primarySharedKey
    }
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'kube-system'
      }
    }
  }
  scope: cluster
}
