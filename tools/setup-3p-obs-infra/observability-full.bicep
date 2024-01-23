// This template deploys both a set of shared observability resources and
// cluster-specific observability resources for connecting to the shared
// resources. The shared resources are meant to be used by multiple clusters/AIO
// deployments to achieve a single location for monitoring across all clusters.
// It is meant to be run against the resource group containing the Arc-enabled
// cluster. A separate resource group can be defined for the shared resources
// if desired.

// Shared resource parameters
@description('Prefix to apply to all monitor resources')
@maxLength(11)
param prefix string = ''

@description('Region where the shared resources should be created')
param sharedResourceLocation string = resourceGroup().location

@description('Resource group where the shared resources should be created. Leave blank to use the same resource group as the cluster')
param sharedResourceGroup string = resourceGroup().name

@description('Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users')
param grafanaAdminId string = ''

@description('Major version of grafana to use')
param grafanaMajorVersion string = '10'

@description('Duration to retain logs in log analytics')
param logRetentionInDays int = 30

// Cluster resource parameters
@description('Name of the cluster to monitor')
@minLength(1)
param clusterName string

@description('Region where the cluster-connected resources should be created')
param clusterLocation string = resourceGroup().location

@description('Interval to scrape metrics from the cluster')
param scrapeInterval string = 'PT1M'

@description('Domain of Azure Monitor logs. Do not change unless using a sovereign cloud')
param amaLogsDomain string = 'opinsights.azure.com'

module observability './observability.bicep' = {
  name: 'observability'
  params: {
    prefix: prefix
    location: sharedResourceLocation
    grafanaAdminId: grafanaAdminId
    grafanaMajorVersion: grafanaMajorVersion
    logRetentionInDays: logRetentionInDays
  }
  scope: resourceGroup(sharedResourceGroup)
}

module cluster './cluster.bicep' = {
  name: 'cluster'
  params: {
    clusterName: clusterName
    location: clusterLocation
    azureMonitorId: observability.outputs.azureMonitorId
    logAnalyticsId: observability.outputs.logAnalyticsId
    azureMonitorLocation: sharedResourceLocation
    logAnalyticsLocation: sharedResourceLocation
    scrapeInterval: scrapeInterval
    amaLogsDomain: amaLogsDomain
  }
}

output grafanaEndpoint string = observability.outputs.grafanaEndpoint
output azureMonitorId string = observability.outputs.azureMonitorId
output logAnalyticsId string = observability.outputs.logAnalyticsId
