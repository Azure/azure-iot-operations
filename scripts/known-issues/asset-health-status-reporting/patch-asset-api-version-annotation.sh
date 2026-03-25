#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Patch NamespaceAsset API Version Annotation
#
# Finds all NamespaceAsset CRs in azure-iot-operations namespace with an
# management.azure.com/apiVersion annotation older than 2026-04-01, then
# patches them to 2026-04-01.
#
# This is a workaround for a known issue where status.healthState is not
# synced to ARM unless the annotation is updated to 2026-04-01.
# =============================================================================

NAMESPACE="azure-iot-operations"
TARGET_API_VERSION="2026-04-01"
CRD="assets.namespaces.deviceregistry.microsoft.com"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Get all namespace assets with their API version annotation
log_info "Scanning NamespaceAssets in namespace '${NAMESPACE}'..."

ALL_ASSETS=$(kubectl get "${CRD}" -n "${NAMESPACE}" --request-timeout=30s \
  -o custom-columns='NAME:.metadata.name,API_VERSION:.metadata.annotations.management\.azure\.com/apiVersion' \
  --no-headers 2>/dev/null) || true

if [ -z "${ALL_ASSETS}" ]; then
  log_info "No NamespaceAssets found. Nothing to do."
  exit 0
fi

TOTAL=$(echo "${ALL_ASSETS}" | wc -l)
log_info "Found ${TOTAL} total NamespaceAsset(s)"

# Filter assets with annotation < TARGET_API_VERSION (lexicographic compare works for YYYY-MM-DD)
OUTDATED=""
while IFS= read -r line; do
  # Parse name (first column) and version (second column) from whitespace-separated output
  name=$(echo "${line}" | awk '{print $1}')
  version=$(echo "${line}" | awk '{print $2}')
  # Treat <none> or empty as "unknown"
  if [ -z "${version}" ] || [ "${version}" = "<none>" ]; then
    version="unknown"
  fi
  if [[ "${version}" == "unknown" || "${version}" < "${TARGET_API_VERSION}" ]]; then
    if [ -z "${OUTDATED}" ]; then
      OUTDATED="${name}	${version}"
    else
      OUTDATED="${OUTDATED}
${name}	${version}"
    fi
  fi
done <<< "${ALL_ASSETS}"

if [ -z "${OUTDATED}" ]; then
  log_info "All NamespaceAssets already have apiVersion >= ${TARGET_API_VERSION}. Nothing to patch."
  exit 0
fi

OUTDATED_COUNT=$(echo "${OUTDATED}" | wc -l)

echo ""
echo -e "${CYAN}NamespaceAssets with apiVersion annotation < ${TARGET_API_VERSION}:${NC}"
echo ""
printf "  %-40s %s\n" "RESOURCE NAME" "CURRENT API VERSION"
printf "  %-40s %s\n" "----------------------------------------" "-------------------"
while IFS=$'\t' read -r name version; do
  printf "  %-40s %s\n" "${name}" "${version}"
done <<< "${OUTDATED}"
echo ""
log_warn "${OUTDATED_COUNT} resource(s) need patching to ${TARGET_API_VERSION}"
echo ""

# Ask for user confirmation
read -rp "Apply annotation patch to all ${OUTDATED_COUNT} resource(s)? [y/N] " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
  log_info "User declined. Exiting without changes."
  exit 0
fi

echo ""
PATCHED=0
FAILED=0

while IFS=$'\t' read -r name version; do
  if kubectl annotate "${CRD}" "${name}" -n "${NAMESPACE}" \
    "management.azure.com/apiVersion=${TARGET_API_VERSION}" \
    --overwrite --request-timeout=15s 2>/dev/null; then
    log_info "Patched ${name}: ${version} -> ${TARGET_API_VERSION}"
    PATCHED=$((PATCHED + 1))
  else
    log_error "Failed to patch ${name}"
    FAILED=$((FAILED + 1))
  fi
done <<< "${OUTDATED}"

echo ""
log_info "Done. Patched: ${PATCHED}, Failed: ${FAILED}"
