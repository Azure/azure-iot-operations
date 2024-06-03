param ruleGroupPrefix string = 'ScenarioRollups'
param ruleGroupDescription string = 'AIO scenario quality KPI rollups'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Rollup KPI for Dataflow health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_scenario_dataflow'
    kpi: 'aio.scenario.dataflow'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_scenario_dataflow_mq or
        aio_health_scenario_dataflow_opcua or
        aio_health_scenario_dataflow_dp or
        vector(0) > 0 # bookend for trailing 'or'
      )
    '''
  }
]

// Child modules for scenario rule groups

module aioDataflowMqKpiRuleGroup './dataflow/aioDataflowMqKpiRuleGroup.bicep' = {
  name: 'aioDataflowMqKpiRuleGroup'
  params: {
    clusterScope: clusterScope
    workspaceScope: workspaceScope
    location: location
  }
}

module aioDataflowOpcKpiRuleGroup './dataflow/aioDataflowOpcKpiRuleGroup.bicep' = {
  name: 'aioDataflowOpcKpiRuleGroup'
  params: {
    clusterScope: clusterScope
    workspaceScope: workspaceScope
    location: location
  }
}

module aioDataflowDpKpiRuleGroup './dataflow/aioDataflowDpKpiRuleGroup.bicep' = {
  name: 'aioDataflowDpKpiRuleGroup'
  params: {
    clusterScope: clusterScope
    workspaceScope: workspaceScope
    location: location
  }
}

module aioScaleTestingKpiRuleGroup './scale/aioScaleTestingKpiRuleGroup.bicep' = {
  name: 'aioScaleTestingKpiRuleGroup'
  params: {
    clusterScope: clusterScope
    workspaceScope: workspaceScope
    location: location
  }
}

// Add additional scenario rule group modules here

module qualityKpis '../common/aio-quality-kpi.bicep' = {
  name: '${deployment().name}-CreateRuleGroup'
  params: {
    rules: rules
    ruleGroupPrefix: ruleGroupPrefix
    ruleGroupDescription: ruleGroupDescription
    location: location
    scopeWorkspace: workspaceScope
    scopeCluster: clusterScope }
}
