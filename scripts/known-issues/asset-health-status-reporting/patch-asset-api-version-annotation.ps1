#Requires -Version 5.1

<#
.SYNOPSIS
    Patch NamespaceAsset API Version Annotation to 2026-04-01

.DESCRIPTION
    Finds all NamespaceAsset CRs in azure-iot-operations namespace with a
    management.azure.com/apiVersion annotation older than 2026-04-01, then
    patches them to 2026-04-01 after asking for user confirmation.

    This is a workaround for a known issue where status.healthState is not
    synced to ARM unless the annotation is updated to 2026-04-01.

.PARAMETER Force
    Skip the interactive confirmation prompt and apply patches immediately.
    Useful for unattended or scripted execution.
#>
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$Namespace = "azure-iot-operations"
$TargetApiVersion = "2026-04-01"
$Crd = "assets.namespaces.deviceregistry.microsoft.com"

function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err   { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Get all namespace assets with their API version annotation
Write-Info "Scanning NamespaceAssets in namespace '$Namespace'..."

$rawOutput = kubectl get $Crd -n $Namespace --request-timeout=30s `
    -o "custom-columns=NAME:.metadata.name,API_VERSION:.metadata.annotations.management\.azure\.com/apiVersion" `
    --no-headers 2>$null

if ($LASTEXITCODE -ne 0 -or -not $rawOutput) {
    Write-Info "No NamespaceAssets found. Nothing to do."
    exit 0
}

$lines = $rawOutput -split "`n" | Where-Object { $_.Trim() -ne "" }
$total = $lines.Count
Write-Info "Found $total total NamespaceAsset(s)"

# Filter assets with annotation < TARGET_API_VERSION
$outdated = @()
foreach ($line in $lines) {
    $parts = $line.Trim() -split '\s+', 2
    $name = $parts[0]
    $version = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }

    # Treat <none> or empty as "unknown"
    if (-not $version -or $version -eq "<none>") {
        $version = "unknown"
    }

    if ($version -eq "unknown" -or $version -lt $TargetApiVersion) {
        $outdated += [PSCustomObject]@{ Name = $name; Version = $version }
    }
}

if ($outdated.Count -eq 0) {
    Write-Info "All NamespaceAssets already have apiVersion >= $TargetApiVersion. Nothing to patch."
    exit 0
}

Write-Host ""
Write-Host "NamespaceAssets with apiVersion annotation < ${TargetApiVersion}:" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  {0,-40} {1}" -f "RESOURCE NAME", "CURRENT API VERSION")
Write-Host ("  {0,-40} {1}" -f ("─" * 40), ("─" * 19))
foreach ($item in $outdated) {
    Write-Host ("  {0,-40} {1}" -f $item.Name, $item.Version)
}
Write-Host ""
Write-Warn "$($outdated.Count) resource(s) need patching to $TargetApiVersion"
Write-Host ""

# Ask for user confirmation
if (-not $Force) {
    $confirm = Read-Host "Apply annotation patch to all $($outdated.Count) resource(s)? [y/N]"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Info "User declined. Exiting without changes."
        exit 0
    }
}

Write-Host ""
$patched = 0
$failed = 0

foreach ($item in $outdated) {
    kubectl annotate $Crd $item.Name -n $Namespace `
        "management.azure.com/apiVersion=$TargetApiVersion" `
        --overwrite --request-timeout=15s 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Info "Patched $($item.Name): $($item.Version) -> $TargetApiVersion"
        $patched++
    } else {
        Write-Err "Failed to patch $($item.Name)"
        $failed++
    }
}

Write-Host ""
Write-Info "Done. Patched: $patched, Failed: $failed"
