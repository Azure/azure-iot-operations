param ruleGroupPrefix string = 'ServiceLnm'
param ruleGroupDescription string = 'AIO quality KPIs for LayeredNwMgmt Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for LayeredNwMgmt server uptime:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_lnm_server_uptime'
    promQL: '''
      max by(cluster, namespace)(label_replace(
        rate(server_uptime[5m:1m])
      ,"namespace", "azure-iot-operations", "", ""))  
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_lnm_server_uptime'
    kpi: 'aio.service.lnm.server.uptime'
    promQL: '''
      1 * sgn(max by(cluster, namespace)(aio_signal_service_lnm_server_uptime) > 0) or
      0 * sgn(max by(cluster, namespace)(aio_signal_service_lnm_server_uptime) <= 0)
    '''
  }
  // Rollup KPI for LayeredNwMgmt health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_lnm'
    kpi: 'aio.service.lnm'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_service_lnm_server_uptime or
        vector(0) > 0 # bookend for trailing 'or'
      )
    '''
  }
]

module qualityKpis '../common/aio-quality-kpi.bicep' = {
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
