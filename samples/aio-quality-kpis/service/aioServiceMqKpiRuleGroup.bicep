param ruleGroupPrefix string = 'ServiceMq'
param ruleGroupDescription string = 'AIO quality KPIs for MQ Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // HealthState KPI for MQ publish health:
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_mq_publish'
    kpi: 'aio.service.mq.publish'
    promQL: '''
      min by(cluster, namespace)(
        label_replace(aio_mq_publish_route_replication_correctness,
            "namespace", "azure-iot-operations", "", ""))
    '''
  }
  // HealthState KPI for MQ subscribe health:
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_mq_subscribe'
    kpi: 'aio.service.mq.subscribe'
    promQL: '''
      min by(cluster, namespace)(
        label_replace(aio_mq_subscribe_route_replication_correctness,
            "namespace", "azure-iot-operations", "", ""))
    '''
  }
  // HealthState KPI for MQ unsubscribe health:
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_mq_unsubscribe'
    kpi: 'aio.service.mq.unsubscribe'
    promQL: '''
      min by(cluster, namespace)(
        label_replace(aio_mq_unsubscribe_route_replication_correctness,
            "namespace", "azure-iot-operations", "", ""))
    '''
  }
  // Signal and HealthState KPIs for MQ E2E health:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_mq_e2e_total_messages_lost'
    promQL: '''
      sum by(cluster, namespace)(
        label_replace(aio_mq_payload_check_total_messages_lost,
            "namespace", "azure-iot-operations", "", ""))    
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_mq_e2e'
    kpi: 'aio.service.mq.e2e'
    promQL: '''1 - min by(cluster, namespace)(0 * sgn(aio_signal_service_mq_e2e_total_messages_lost <= 0)
      or 1 * sgn(aio_signal_service_mq_e2e_total_messages_lost > 0))'''
  }
  // Rollup KPI for MQ health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_mq'
    kpi: 'aio.service.mq'
    promQL: '''
      min by(cluster) (
        aio_health_service_mq_publish or
        aio_health_service_mq_subscribe or
        aio_health_service_mq_unsubscribe or
        aio_health_service_mq_e2e or
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
