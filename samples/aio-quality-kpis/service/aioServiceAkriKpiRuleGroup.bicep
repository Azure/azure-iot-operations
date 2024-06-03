param ruleGroupPrefix string = 'ServiceAkri'
param ruleGroupDescription string = 'AIO quality KPIs for Akri Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // HealthState KPI for Akri workload readiness:
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_akri_workload_readiness'
    kpi: 'aio.service.akri.workload.readiness'
    promQL: '''
      min by(cluster, namespace)(floor(aio_signal_workload_readiness{workload=~"(daemonset|deployment|statefulset):aio-akri-agent.*"}))
    '''
  }
  // Rollup KPI for Akri health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_akri'
    kpi: 'aio.service.akri'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_service_akri_workload_readiness or
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
    scopeCluster: clusterScope}
}
