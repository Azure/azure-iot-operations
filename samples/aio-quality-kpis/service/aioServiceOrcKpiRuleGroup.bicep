param ruleGroupPrefix string = 'ServiceOrchestration'
param ruleGroupDescription string = 'AIO quality KPIs for Orchestration Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for self-test API Operation latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_api_operation_latency'
    promQL: '''
      histogram_quantile(0.95,
        sum by(le,cluster,namespace)(label_replace(
          rate(aio_orc_api_operation_latency_bucket[5m:1m])
        ,"namespace", "azure-iot-operations", "", "")) 
      )
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_orc_api_operation_latency'
    kpi: 'aio.service.orc.api.operation.latency'
    promQL: '''
      1 - sgn(floor(min by(cluster, namespace)(aio_signal_service_orc_api_operation_latency) / 60000))
    '''
  }
  // Signal and HealthState KPIs for self-test API Operation errors:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_api_operation_errors'
    promQL: '''
      round(sum by(cluster, namespace)(label_replace(
        increase(aio_orc_api_operation_errors[5m:1m])
      ,"namespace", "azure-iot-operations", "", "")))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_api_operation_latency_count'
    promQL: '''
      sum by(cluster, namespace)(label_replace(aio_orc_api_operation_latency_count
        ,"namespace", "azure-iot-operations", "", ""))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_orc_api_operation_errors'
    kpi: 'aio.service.orc.api.operation.errors'
    promQL: ''' 
      0 * sgn(min by(cluster, namespace)(aio_signal_service_orc_api_operation_errors) > 0) or
      1 * sgn(min by(cluster, namespace)(aio_signal_service_orc_api_operation_latency_count))
    '''
  }
  // Signal and HealthState KPIs for self-test Provider Operation latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_provider_operation_latency'
    promQL: '''
      histogram_quantile(0.95,
        sum by(le,cluster,namespace)(label_replace(
          rate(aio_orc_provider_operation_latency_bucket[5m:1m])
        ,"namespace", "azure-iot-operations", "", "")) 
      )
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_orc_provider_operation_latency'
    kpi: 'aio.service.orc.provider.operation.latency'
    promQL: '''
      1 - sgn(floor(min by(cluster, namespace)(aio_signal_service_orc_provider_operation_latency) / 60000))
    '''
  }
  // Signal and HealthState KPIs for self-test Provider Operation errors:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_provider_operation_errors'
    promQL: '''
      round(sum by(cluster, namespace)(label_replace(
        increase(aio_orc_provider_operation_errors[5m:1m])
      ,"namespace", "azure-iot-operations", "", "")))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_orc_provider_operation_latency_count'
    promQL: '''
      sum by(cluster, namespace)(label_replace(aio_orc_provider_operation_latency_count
        ,"namespace", "azure-iot-operations", "", ""))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_orc_provider_operation_errors'
    kpi: 'aio.service.orc.provider.operation.errors'
    promQL: ''' 
      0 * sgn(min by(cluster, namespace)(aio_signal_service_orc_provider_operation_errors) > 0) or
      1 * sgn(min by(cluster, namespace)(aio_signal_service_orc_provider_operation_latency_count))
    '''
  }
  // Rollup KPI for Orchestration service health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_orc'
    kpi: 'aio.service.orc'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_service_orc_api_operation_latency or
        aio_health_service_orc_api_operation_errors or
        aio_health_service_orc_provider_operation_latency or
        aio_health_service_orc_provider_operation_errors or
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
