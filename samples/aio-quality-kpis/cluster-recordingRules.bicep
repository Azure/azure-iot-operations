@description('Resource ID of Azure Monitor workspace containing Managed Prometheus')
@minLength(1)
param azureMonitorId string

@description('Resource ID of the cluster to monitor')
@minLength(1)
param clusterId string

@description('The location where the rule groups should be created; MUST be same as the location of the Azure Monitor workspace containing Managed Prometheus.')
param location string

// Call into each child module to deploy their KPI rule groups

module aioNodeKpiRuleGroup './infra/aioNodeKpiRuleGroup.bicep' = {
  name: 'aioNodeKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioWorkloadKpiRuleGroup './infra/aioWorkloadKpiRuleGroup.bicep' = {
  name: 'aioWorkloadKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioScenarioKpiRuleGroup './scenario/aioScenarioRollup.bicep' = {
  name: 'aioScenarioKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceMqKpiRuleGroup './service/aioServiceMqKpiRuleGroup.bicep' = {
  name: 'aioServiceMqKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceOpcKpiRuleGroup './service/aioServiceOpcKpiRuleGroup.bicep' = {
  name: 'aioServiceOpcKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceAkriKpiRuleGroup './service/aioServiceAkriKpiRuleGroup.bicep' = {
  name: 'aioServiceAkriKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceDpKpiRuleGroup './service/aioServiceDpKpiRuleGroup.bicep' = {
  name: 'aioServiceDpKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceLnmKpiRuleGroup './service/aioServiceLnmKpiRuleGroup.bicep' = {
  name: 'aioServiceLnmKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

module aioServiceOrcKpiRuleGroup './service/aioServiceOrcKpiRuleGroup.bicep' = {
  name: 'aioServiceOrcKpiRuleGroup'
  params: {
    clusterScope: clusterId
    workspaceScope: azureMonitorId
    location: location
  }
}

// Add more module calls for other child modules here
