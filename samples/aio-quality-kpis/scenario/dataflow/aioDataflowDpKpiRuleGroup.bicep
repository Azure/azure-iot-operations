param ruleGroupPrefix string = 'DataflowDp'
param ruleGroupDescription string = 'AIO quality KPIs for DP Dataflow Scenario Health'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for DP pipeline success rate:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_errors'
    promQL: '''
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_reader_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) + 
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_stage_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
      or  
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_reader_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) unless 
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_stage_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
      or  
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_stage_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) unless 
      sum by(cluster, namespace, error_code, pipeline_id)(label_replace(
        rate(aio_dp_reader_errors[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_incoming_messages'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) +
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
      or
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) unless
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
      or
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)")) +
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_incoming_messages[5m:1m]),"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_dp_pipeline_success_rate'
    kpi: 'aio.scenario.dataflow.dp.pipeline.successrate'
    promQL: '''
      1 - sgn(sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_errors) / 
      sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_incoming_messages) > 0.05)
      or sgn(sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_incoming_messages) > 0)
    '''
  }
  // Signal and HealthState KPIs for DP pipeline latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_pipeline_latency'
    promQL: '''
      histogram_quantile(0.95,
        sum by(le,cluster,namespace, pipeline_id)(label_replace(
              rate(aio_dp_pipeline_latency_bucket[5m:1m])
        ,"namespace","$1","k8s_namespace_name","(.*)"))
      ) 
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_dp_pipeline_latency'
    kpi: 'aio.scenario.dataflow.dp.pipeline.latency'
    promQL: '1 - sgn(floor(max by(cluster, namespace)(aio_signal_scenario_dataflow_dp_pipeline_latency) / 5000))'
  }
  // Signal and HealthState KPIs for DP pipeline heartbeats:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_reader_processed_heartbeats'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_processed_heartbeats[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_reader_incoming_heartbeats'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_reader_incoming_heartbeats[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_dp_stage_heartbeats'
    promQL: '''
      sum by(cluster, namespace, pipeline_id)(label_replace(
        rate(aio_dp_stage_heartbeats[5m:1m])
      ,"namespace","$1","k8s_namespace_name","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_dp_pipeline_heartbeats'
    kpi: 'aio.scenario.dataflow.dp.pipeline.heartbeats'
    promQL: '''
      sgn(sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_reader_processed_heartbeats)
       >= sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_reader_incoming_heartbeats))
      or sgn(sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_stage_heartbeats)
       >= sum by(cluster, namespace)(aio_signal_scenario_dataflow_dp_reader_processed_heartbeats))
    '''
  }

  // Rollup KPI for DP Scenario health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_scenario_dataflow_dp'
    kpi: 'aio.scenario.dataflow.dp'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_scenario_dataflow_dp_pipeline_success_rate or
        aio_health_scenario_dataflow_dp_pipeline_latency or
        aio_health_scenario_dataflow_dp_pipeline_heartbeats or
        vector(0) > 0 # bookend for trailing 'or'
      )
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
    scopeCluster: clusterScope}
}
