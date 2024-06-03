param ruleGroupPrefix string = 'ServiceDp'
param ruleGroupDescription string = 'AIO quality KPIs for DP Service Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for DP self-test input:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_dp_selftest_input'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_incoming_messages{cloud_resource_id=~".*self-test-pipeline.*"}[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))  
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_dp_selftest_input'
    kpi: 'aio.service.dp.selftest.input'
    promQL: 'sgn(min by(cluster, namespace)(aio_signal_service_dp_selftest_input))'
  }
  // Signal and HealthState KPIs for DP self-test stage errors:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_dp_selftest_stage_errors'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_errors{cloud_resource_id=~".*self-test-pipeline.*"}[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_dp_selftest_stage_incoming_messages'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_incoming_messages{stage_type=~"output/.*",cloud_resource_id=~".*self-test-pipeline.*"}[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_dp_selftest_stage_errors'
    kpi: 'aio.service.dp.selftest.stage.errors'
    promQL: '''
      0 * sgn(min by(cluster, namespace)(aio_signal_service_dp_selftest_stage_errors) > 0) or
      1 * sgn(min by(cluster, namespace)(aio_signal_service_dp_selftest_stage_incoming_messages))
    '''
  }
  // Signal and HealthState KPIs for DP self-test output:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_dp_selftest_output'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_incoming_messages{stage_type=~"output/.*", cloud_resource_id=~".*self-test-pipeline.*"}[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))  
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_dp_selftest_output'
    kpi: 'aio.service.dp.selftest.output'
    promQL: 'sgn(min by(cluster, namespace)(aio_signal_service_dp_selftest_output))'
  }
  // Signal and HealthState KPIs for DP self-test pipeline latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_service_dp_selftest_pipeline_latency'
    promQL: '''
      histogram_quantile(0.95,
        sum by(le,cluster,namespace, pipeline_id)(label_replace(
              rate(aio_dp_pipeline_latency_bucket{cloud_resource_id=~".*self-test-pipeline.*"}[5m:1m])
        ,"namespace","$1","k8s_namespace_name","(.*)"))
      ) 
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_service_dp_selftest_pipeline_latency'
    kpi: 'aio.service.dp.selftest.pipeline.latency'
    promQL: '1 - sgn(floor(max by(cluster, namespace)(aio_signal_scenario_dataflow_dp_pipeline_latency) / 5000))'
  }
  // Rollup KPI for DP health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_service_dp'
    kpi: 'aio.service.dp'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_service_dp_selftest_input or
        aio_health_service_dp_selftest_stage_errors or
        aio_health_service_dp_selftest_output or
        aio_health_service_dp_selftest_pipeline_latency or
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
