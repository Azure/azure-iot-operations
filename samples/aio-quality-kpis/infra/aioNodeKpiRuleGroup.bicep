param ruleGroupPrefix string = 'Node'
param ruleGroupDescription string = 'AIO quality KPIs for Node health.'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'
param rules KpiRule[] = [
  // Signal and HealthState KPIs for Node readiness:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_node_readiness'
    promQL: 'sum by(cluster,node,condition) (kube_node_status_condition{condition="ready",status="true"})'
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_node_readiness'
    kpi: 'aio.node.readiness'
    promQL: 'max by(cluster)(aio_signal_node_readiness)'
  }
  // Signal and HealthState KPIs for Node CPU:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_node_cpu'
    promQL: '''
      max by(cluster,node)(label_replace(
        1 - ((avg by (cluster,instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) 
              + avg by (cluster,instance) (rate(node_cpu_seconds_total{mode="iowait"}[5m]))
        ) * 1) 
      ,"node","$1","instance","(.*)"))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_node_cpu'
    kpi: 'aio.node.cpu'
    promQL: 'max by(cluster)(1 - floor(100 * aio_signal_node_cpu / 95)) # Threshold for red'
  }
  // Signal and HealthState KPIs for Node Memory:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_node_memory'
    promQL: '''
      max by(cluster,node)(label_replace(1
        * sum by(cluster,instance)(node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes)) 
        / sum by(cluster,instance)(node_memory_MemTotal_bytes)
      ,"node","$1","instance","(.*)"))  
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_node_memory'
    kpi: 'aio.node.memory'
    promQL: 'max by(cluster)(1 - floor(100 * aio_signal_node_memory / 96)) # Threshold for red'
  }
  // Signal and HealthState KPIs for Node Disk Capacity:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_node_disk'
    promQL: '''
      max by(cluster,node,device,mountpoint)(label_replace(0.10 < # Min bar for signal
        1 - (1 * node_filesystem_avail_bytes / node_filesystem_size_bytes)
      ,"node","$1","instance","(.*)"))   
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_node_disk'
    kpi: 'aio.node.disk'
    // NOTE: we take `min` instead of `max` to highlight any disk that is full
    promQL: 'min by(cluster)(1 - floor(100 * aio_signal_node_disk / 99)) # Threshold for red'
  }
  // Rollup KPI for node health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_node'
    kpi: 'aio.node'
    promQL: '''
      min by(cluster) (
        aio_health_node_readiness or
        aio_health_node_cpu or
        aio_health_node_memory or
        aio_health_node_disk or
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
    scopeCluster: clusterScope }
}
