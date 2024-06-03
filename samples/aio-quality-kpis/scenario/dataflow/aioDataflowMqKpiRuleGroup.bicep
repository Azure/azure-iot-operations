param ruleGroupPrefix string = 'DataflowMq'
param ruleGroupDescription string = 'AIO quality KPIs for Dataflow Scenario Health from MQ service'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for MQ authentication:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_mq_authentication'
    promQL: '''
      # MQ authentication failures
      sum by(cluster, namespace, category)(rate(aio_mq_authentication_failures{category!="broker_selftest"}[2m]))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_mq_authentication'
    kpi: 'aio.scenario.dataflow.mq.authentication'
    promQL: '''
      1 - sgn(floor(sum by(cluster, namespace)(aio_signal_scenario_dataflow_mq_authentication) / 20))
      or sgn(count by(cluster,namespace)(aio_mq_authentication_successes)) # smooth health signal
    '''
  }
  // Signal and HealthState KPIs for MQ authorization:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_mq_authorization'
    promQL: '''
      # MQ authorization failures
      sum by(cluster, namespace, category)(rate(aio_mq_authorization_deny{category!="broker_selftest"}[2m]))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_mq_authorization'
    kpi: 'aio.scenario.dataflow.mq.authorization'
    promQL: '''
      1 - sgn(floor(sum by(cluster, namespace)(aio_signal_scenario_dataflow_mq_authorization) / 20))
      or sgn(count by(cluster,namespace)(aio_mq_authorization_allow)) # smooth health signal
    '''
  }
  // Signal and HealthState KPIs for MQ backpressure:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_mq_backpressure'
    promQL: '''
      sum by(cluster, namespace)(rate(aio_mq_backpressure_packets_rejected{pod_type="BE", category!="broker_selftest"}[2m])) / 
      sum by(cluster, namespace)(quantile_over_time(.95, rate(aio_mq_publishes_received{pod_type="FE"}[2m])[30m:1m]))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_mq_backpressure'
    kpi: 'aio.scenario.dataflow.mq.backpressure'
    promQL: '''
      1 - sgn(floor(sum by(cluster, namespace)(aio_signal_scenario_dataflow_mq_backpressure) / 0.05))
      or sgn(count by(cluster,namespace)(aio_mq_publishes_received)) # smooth health signal
    '''
  }
  // Signal and HealthState KPIs for MQ dropped QoS0 Messages:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_mq_qos0_messages'
    promQL: '''
      sum by(cluster, namespace)(rate(aio_mq_qos0_messages_dropped{pod_type="BE",category!="broker_selftest"}[2m])) / 
      sum by(cluster, namespace)(quantile_over_time(.95, rate(aio_mq_publishes_received{pod_type="FE"}[2m])[30m:1m]))      
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_mq_qos0_messages'
    kpi: 'aio.scenario.dataflow.mq.qos0'
    promQL: '''
      1 - sgn(floor(sum by(cluster, namespace)(aio_signal_scenario_dataflow_mq_qos0_messages) / 0.05))
      or sgn(count by(cluster,namespace)(aio_mq_publishes_received)) # smooth health signal
    '''
  }
  // Rollup KPI for MQ health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_scenario_dataflow_mq'
    kpi: 'aio.scenario.dataflow.mq'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_scenario_dataflow_mq_authentication or
        aio_health_scenario_dataflow_mq_authorization or
        aio_health_scenario_dataflow_mq_backpressure or
        aio_health_scenario_dataflow_mq_qos0_messages or
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
