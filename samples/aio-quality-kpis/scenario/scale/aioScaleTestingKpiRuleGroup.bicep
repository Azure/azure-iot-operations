param ruleGroupPrefix string = 'Scale'
param ruleGroupDescription string = 'AIO quality KPIs for Scale Testing Scenario Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for Scale error:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_scale_errors'
    promQL: '''
      sum by(cluster,namespace)(label_replace(locust_requests_num_failures ,"namespace","$1","kubernetes_namespace","(.*)"))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_health_scenario_scale_errors'
    promQL: '''
      1 - sgn(sum by(cluster,namespace)(aio_signal_scenario_scale_errors))
    '''
  }
]

module qualityKpis '../../common/aio-quality-kpi.bicep' = {
  name: '${deployment().name}-CreateRuleGroup'
  params: {
    rules: rules
    ruleGroupPrefix: ruleGroupPrefix
    ruleGroupDescription: ruleGroupDescription
    location: location
    scopeWorkspace: workspaceScope
    scopeCluster: clusterScope
  }
}
