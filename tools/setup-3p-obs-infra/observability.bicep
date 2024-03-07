// This template deploys a set of shared observability resources and configures
// them to work together. The resources created by this template can be used by
// as many clusters/AIO deployments as desired to achieve a single location for
// monitoring across all clusters.

@description('Prefix to apply to all monitor resources')
@maxLength(11)
param prefix string = ''

// This is intended as a hidden parameter to allow the parent prefix parameter
// to allow an empty default to be passed from parent deployments while allowing
// the actual default to be reasonable. This is necessary because we can't
// properly set the default value in the parent template.
var _prefix = prefix != '' ? prefix : 'aio-obs-${substring(uniqueString(resourceGroup().id), 0, 3)}'

@description('Region where the resources should be created')
param location string = resourceGroup().location

@description('Object id of a user to grant grafana admin access to. Leave blank to not grant access to any users')
param grafanaAdminId string = ''

@description('Major version of grafana to use')
param grafanaMajorVersion string = '10'

@description('Duration to retain logs in log analytics')
param logRetentionInDays int = 30

// Azure Monitor workspace. This holds the Managed Prometheus instance that
// serves metrics used by Grafana dashboards.
resource azmon 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: '${_prefix}-azmon'
  location: location
}

// Log Analytics workspace which holds logs collected from the connected
// clusters that is used by Grafana dashboards.
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${_prefix}-logAnalytics'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: logRetentionInDays
  }
}

// Container Insights solution which collects logs from containers in the
// connected clusters and writes them to the ContainerLogV2 table in the Log
// Analytics workspace.
resource containerInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalytics.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalytics.id
  }
  plan: {
    name: 'ContainerInsights(${logAnalytics.name})'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

// Azure Managed Grafana instance. This is used to host dashboards that pull
// metrics from the Managed Prometheus instance and logs from the Log Analytics
// workspace.
resource grafana 'Microsoft.Dashboard/grafana@2022-10-01-preview' = {
  name: '${_prefix}-grafana'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    grafanaMajorVersion: grafanaMajorVersion
    zoneRedundancy: 'Disabled'
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    publicNetworkAccess: 'Enabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: azmon.id
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Give the user specified in the template parameters full admin access to the
// grafana instance if a user id was provided.
resource grafanaUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (grafanaAdminId != '') {
  name: guid(grafana.id, grafanaAdminId, 'admin')
  scope: grafana
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '22926164-76b3-42b3-bc55-97df8dab3e41') // Grafana Admin
    principalType: 'User'
    principalId: grafanaAdminId
  }
}

// Give Grafana dashboards permission to read logs from the log analytics
// workspace. We use the generic Reader role here rather than Monitoring Data
// Reader because the former allows Grafana to see the full resource for
// purposes of data source setup. Monitoring Data Reader can also be used if
// desired.
resource grafanaLogsReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(grafana.id, 'logsReaderRole')
  scope: logAnalytics
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    principalType: 'ServicePrincipal'
    principalId: grafana.identity.principalId
  }
}

// Give Grafana dashboards permission to read metrics from Prometheus in the
// Azure Monitor workspace
resource grafanaMetricsReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(grafana.id, 'metricsReaderRole')
  scope: azmon
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b0d8363b-8ddd-447d-831f-62ca05bff136') // Monitoring Data Reader
    principalType: 'ServicePrincipal'
    principalId: grafana.identity.principalId
  }
}

// Outputs used for connecting to the grafana instance and resource ids used for
// subsequent deployments.
output grafanaEndpoint string = grafana.properties.endpoint
output azureMonitorId string = azmon.id
output logAnalyticsId string = logAnalytics.id
