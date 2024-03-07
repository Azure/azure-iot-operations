// This template sets up data collection rules on a cluster for both metrics and
// logs. It is designed to be run within the cluster.bicep deployment and not
// as a standalone template.

@description('Name of the cluster to monitor')
@minLength(1)
param clusterName string

@description('Prefix to apply to all monitor resources')
@minLength(1)
@maxLength(50)
param prefix string = '${clusterName}-obs-${substring(uniqueString(resourceGroup().id), 0, 3)}'

@description('Region where the Azure Monitor is located')
param azureMonitorLocation string

@description('Region where the Log Analytics Workspace is located')
param logAnalyticsLocation string

@description('Azure Monitor Resource ID')
param azureMonitorId string

@description('Log Analytics Workspace Resource ID')
param logAnalyticsId string

resource cluster 'Microsoft.Kubernetes/connectedClusters@2023-11-01-preview' existing = {
  name: clusterName
}

// Endpoint where metrics are sent (the Azure Monitor workspace)
resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: '${prefix}-dataCollectionEndpoint'
  location: azureMonitorLocation
  kind: 'Linux'
  properties: {}
}

// Rule for collecting metrics from the cluster
resource metricsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-metricsDataCollectionRule'
  location: azureMonitorLocation
  kind: 'Linux'
  properties: {
    dataCollectionEndpointId: dataCollectionEndpoint.id
    dataFlows: [
      {
        destinations: [ 'MonitoringAccount1' ]
        streams: [ 'Microsoft-PrometheusMetrics' ]
      }
    ]
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [ 'Microsoft-PrometheusMetrics' ]
          labelIncludeFilter: {}
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: azureMonitorId
          name: 'MonitoringAccount1'
        }
      ]
    }
  }
}

// Rule for collecting logs from the cluster
resource logsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-logsDataCollectionRule'
  location: logAnalyticsLocation
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: []
      extensions: [
        {
          name: 'ContainerInsightsExtension'
          streams: [ 'Microsoft-ContainerInsights-Group-Default' ]
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Off'
              enableContainerLogV2: true
            }
          }
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'logAnalytics'
          workspaceResourceId: logAnalyticsId
        }
      ]
    }
    dataFlows: [
      {
        streams: [ 'Microsoft-ContainerInsights-Group-Default' ]
        destinations: [ 'logAnalytics' ]
      }
    ]
  }
}

// Associate the metrics rule with our specific cluster
resource metricsDataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: metricsDataCollectionRule.name
  properties: {
    description: 'Association of metrics data collection rule. Deleting this association will break the data collection for this cluster.'
    dataCollectionRuleId: metricsDataCollectionRule.id
  }
  scope: cluster
}

// Associate the logs rule with our specific cluster
resource logsDataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: logsDataCollectionRule.name
  properties: {
    description: 'Association of logs data collection rule. Deleting this association will break the data collection for this cluster.'
    dataCollectionRuleId: logsDataCollectionRule.id
  }
  scope: cluster
}
