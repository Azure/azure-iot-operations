param ruleGroupPrefix string = 'ServiceOpc'
param ruleGroupDescription string = 'AIO quality KPIs for OPCUA Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for OPC-UA supervisor success rate:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_opc_supervisor_success_rate'
    promQL: '''
      100 * sum by(cluster, namespace)(label_replace(
        rate(aio_opc_mqtt_message_publishing_duration_count{service_name="supervisor",aio_opc_mqtt_publish_result="Success"}[5m:1m])
        ,"namespace","$1","service_namespace","(.*)"))
      / sum by(cluster, namespace)(label_replace(
        rate(aio_opc_mqtt_message_publishing_duration_count{service_name="supervisor"}[5m:1m])
        ,"namespace","$1","service_namespace","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_opc_supervisor_success_rate'
    kpi: 'aio.service.opc.supervisor.successrate'
    promQL: '''
      sgn(floor(min by(cluster, namespace)(aio_signal_service_opc_supervisor_success_rate) / 99))
    '''
  }
  // Signal and HealthState KPIs for OPCUA supervisor latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_opc_supervisor_latency'
    promQL: '''
      histogram_quantile(0.95,
        sum by(le,cluster,namespace)(label_replace(
              rate(aio_opc_mqtt_message_publishing_duration_bucket{service_name=~"supervisor"}[5m:1m])
        ,"namespace","$1","service_namespace","(.*)")) 
      ) 
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_opc_supervisor_latency'
    kpi: 'aio.service.opc.supervisor.latency'
    promQL: '1 - sgn(floor(min by(cluster, namespace)(aio_signal_service_opc_supervisor_latency) / 5000))'
  }
  // Rollup KPI for OPCUA service health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_opc'
    kpi: 'aio.service.opc'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_service_opc_supervisor_success_rate or
        aio_health_service_opc_supervisor_latency or
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
