param ruleGroupPrefix string = 'DataflowOpc'
param ruleGroupDescription string = 'AIO quality KPIs for Dataflow Scenario Health from OPC-UA service'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../../common/aio-quality-kpi.bicep'

param rules KpiRule[] = [
  // Signal and HealthState KPIs for OPC UA-MQ publish rate:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_opc_mqtt_publish_success_rate'
    promQL: '''
      # Raw Success Rate for MQTT message publishing by app, qos, and opc-ua connector
      min by(cluster,namespace,aio_opc_connector_name)(label_replace(
        rate(aio_opc_mqtt_message_publishing_duration_count{aio_opc_mqtt_publish_result="success"}[5m:1m])
        / rate(aio_opc_mqtt_message_publishing_duration_count[5m:1m])
        ,"namespace","$1","service_namespace","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_opc_mqtt_publish_success_rate'
    kpi: 'aio.scenario.dataflow.opc.mqtt.publish.successrate'
    promQL: 'sgn(floor(min by(cluster, namespace)(aio_signal_scenario_dataflow_opc_mqtt_publish_success_rate) / 0.99999))'
  }
  // Signal and HealthState KPIs for OPC-UA connect success rate:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_opc_connect_success_rate'
    promQL: '''
      # OPC-UA Connect Success Rate
      min by(cluster,namespace,aio_opc_connector_name)(label_replace(
        rate(aio_opc_session_connect_duration_count{service_name="opcua-connector",aio_opc_connect_result="succeeded"}[5m:1m])
         / rate(aio_opc_session_connect_duration_count{service_name="opcua-connector"}[5m:1m])
      ,"namespace","$1","service_namespace","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_opc_connect_success_rate'
    kpi: 'aio.scenario.dataflow.opc.connect.successrate'
    promQL: 'sgn(floor(min by(cluster, namespace)(aio_signal_scenario_dataflow_opc_connect_success_rate) / 0.99999))'
  }
  // Signal and HealthState KPIs for OPC-UA latency for MQTT publishing:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_opc_mqtt_publish_latency'
    promQL: '''
      # Raw Latency for MQTT Publishing
      histogram_quantile(0.95,
        sum by(le,cluster,namespace,aio_opc_connector_name)(label_replace(
              rate(aio_opc_mqtt_message_publishing_duration_bucket{aio_opc_mqtt_publish_result="success"}[5m:1m])
        ,"namespace","$1","service_namespace","(.*)"))
      )
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_opc_mqtt_publish_latency'
    kpi: 'aio.scenario.dataflow.opc.mqtt.publish.latency'
    promQL: '1 - sgn(floor(min by(cluster, namespace)(aio_signal_scenario_dataflow_opc_mqtt_publish_latency) / 5000))'
  }
  // Signal and HealthState KPIs for OPC-UA connect latency:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_scenario_dataflow_opc_connect_latency'
    promQL: '''
      #Raw latency for OPC-UA Connect by app and opc-ua connector    
      histogram_quantile(0.95,
        sum by(le,cluster,namespace,aio_opc_connector_name)(label_replace(
              rate(aio_opc_session_connect_duration_bucket{aio_opc_connect_result="success"}[5m:1m])
        ,"namespace","$1","service_namespace","(.*)"))
      ) 
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_scenario_dataflow_opc_connect_latency'
    kpi: 'aio.scenario.dataflow.opc.connect.latency'
    promQL: '1 - sgn(floor(min by(cluster, namespace)(aio_signal_scenario_dataflow_opc_connect_latency) / 5000))'
  }
  // Rollup KPI for OPC-UA health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_scenario_dataflow_opc'
    kpi: 'aio.scenario.dataflow.opc'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_scenario_dataflow_opc_mqtt_publish_success_rate or
        aio_health_scenario_dataflow_opc_connect_success_rate or
        aio_health_scenario_dataflow_opc_mqtt_publish_latency or
        aio_health_scenario_dataflow_opc_connect_latency or
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
