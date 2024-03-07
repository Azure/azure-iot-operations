@description('The subscription ID of the Azure Monitor workspace where the recording rules should be created')
param azmonWorkspaceSubscriptionId string = subscription().subscriptionId

@description('The resource group of the Azure Monitor workspace where the recording rules should be created')
param azmonWorkspaceResourceGroup string = resourceGroup().name

@description('The name of the Azure Monitor workspace where the recording rules should be created')
param azmonWorkspaceName string

@description('The subscription ID of the cluster to scope the AIO Quality KPI recording rules to.')
param clusterSubscriptionId string = subscription().subscriptionId

@description('The resource group of the cluster to scope the AIO Quality KPI recording rules to.')
param clusterResourceGroup string = resourceGroup().name

@description('The name of the cluster to scope the AIO Quality KPI recording rules to.')
param clusterName string

// Fetch existing resources

resource azureMonitor 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  name: azmonWorkspaceName
  scope: resourceGroup(azmonWorkspaceSubscriptionId, azmonWorkspaceResourceGroup)
}

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
}

// Call into adjacent module with resource IDs

module aioQualityKpiRecordingRules 'cluster-recordingRules.bicep' = {
  name: 'aioQualityKpiRecordingRules'
  params: {
    azureMonitorId: azureMonitor.id
    clusterId: cluster.id
    location: azureMonitor.location
  }
}
