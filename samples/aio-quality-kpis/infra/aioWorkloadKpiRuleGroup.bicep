param ruleGroupPrefix string = 'Workload'
param ruleGroupDescription string = 'AIO quality KPIs for workloads in the cluster. This includes KPIs for readiness, restarts, and other workload health indicators.'
param location string = resourceGroup().location
param workspaceScope string
param clusterScope string

import { KpiRule } from '../common/aio-quality-kpi.bicep'
param rules KpiRule[] = [
  // Signal and HealthState KPIs for readiness:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_workload_readiness'
    promQL: '''
      # Workload ready percents (for deployment, daemonset, and statefulset)
      avg by (cluster, namespace, workload) (
        label_join(label_replace(label_join(
          kube_deployment_status_replicas_ready or
          kube_daemonset_status_number_ready or
          kube_statefulset_status_replicas_ready
          ,"workloadName", "", "deployment", "daemonset", "statefulset")
        ,"workloadType", "$1", "__name__", "kube_(.*)_status_.*")
        / label_replace(label_join(  
          kube_daemonset_status_desired_number_scheduled or
          kube_deployment_spec_replicas or
          kube_statefulset_status_replicas
        ,"workloadName", "", "deployment", "daemonset", "statefulset")
        ,"workloadType", "$1", "__name__", "kube_(.*)_(status|spec)_.*")
        ,"workload", ":", "workloadType", "workloadName")
      ) >= 0
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_workload_readiness'
    kpi: 'aio.workload.readiness'
    promQL: 'min by(cluster, namespace) (floor(aio_signal_workload_readiness))'
  }
  // Signal and HealthState KPIs for restarts:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_workload_restart'
    promQL: '''
      # Show number of cumulative restarts by pod/container in a given cluster/namespace
      ceil(sum_over_time(
        sum by(cluster, namespace, pod, container)
          (rate(kube_pod_container_status_restarts_total[10m:1m]) * 60)
        [1h:1m]))
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_workload_restart'
    kpi: 'aio.workload.restart'
    promQL: '''
      # unhealthy if any pod container has more than 5 restarts in the last hour:
      0 * sgn(max by(cluster, namespace)(aio_signal_workload_restart > 5)) or   # Unhealthy
      1 * sgn(max by(cluster, namespace)(aio_signal_workload_restart + 1 >= 0)) # Healthy
    '''
  }
  // Signal and HealthState KPIs for container CPU throttling:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_workload_cpu'
    promQL: '''
      max by(cluster,namespace,pod,container)(0.2 < # min threshold to eval cpu throttling
        rate(container_cpu_cfs_throttled_periods_total{container!=""}[5m]) 
      / rate(container_cpu_cfs_periods_total{container!=""}[5m])
      ) 
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_workload_cpu'
    kpi: 'aio.workload.cpu'
    promQL: '''
    min by(cluster,namespace)(1 - floor(max by(cluster,namespace)(100 *
      aio_signal_workload_cpu
      ) / 80)) # Threshold for red
      or sgn(0 < count by(cluster,namespace)(container_cpu_cfs_periods_total{container!=""}))
      # The latter or condition smooths the output when no throttling meets min threshold for signal
    '''
  }
  // Signal and HealthState KPIs for container memory:
  {
    ruleType: 'KpiSignal'
    outputMetric: 'aio_signal_workload_memory'
    promQL: '''
      max by(cluster,namespace,pod,container)(0.2 < # min threshold to eval container mem usage
          max by(cluster,namespace,pod,container)(container_memory_working_set_bytes{container!=""}) 
        / min by(cluster,namespace,pod,container)(kube_pod_container_resource_limits{container!="",resource="memory"}) 
      )
    '''
  }
  {
    ruleType: 'KpiHealthState'
    outputMetric: 'aio_health_workload_memory'
    kpi: 'aio.workload.memory'
    promQL: '''
      min by(cluster,namespace)(1 - floor(max by(cluster,namespace)(100 *
        aio_signal_workload_memory
      ) / 95)) # Threshold for red
      or sgn(0 < count by(cluster,namespace)(container_memory_working_set_bytes{container!=""}))
      # The latter or condition smooths the output when no mem usage meets min threshold for signal
    '''
  }
  // Rollup KPI for workload health:
  {
    ruleType: 'KpiHealthStateRollup'
    outputMetric: 'aio_health_workload'
    kpi: 'aio.workload'
    promQL: '''
      min by(cluster, namespace) (
        aio_health_workload_restart or
        aio_health_workload_readiness or
        aio_health_workload_cpu or
        aio_health_workload_memory or
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
