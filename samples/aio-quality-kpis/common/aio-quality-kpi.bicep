// This module creates a rule group in the Managed Prometheus workspace for the given cluster for AIO Quality KPIs

@description('Provides a prefix for the rule group name to differentiate between different rule groups')
@minLength(3)
param ruleGroupPrefix string

@description('The description of the quality-kpi rule group')
param ruleGroupDescription string

@description('The list of KPI rules to create; cannot exceed 20 rules in a single rule group')
@minLength(1)
@maxLength(20)
param rules KpiRule[]

@description('The scope of the Managed Prometheus workspace to create the rule group in')
param scopeWorkspace string

@description('The scope of the Arc-enabled K8s cluster to create the rule group for')
param scopeCluster string

@allowed(['PT1M','PT5M','PT10M','PT15M','PT30M','PT1H'])
@description('The interval at which the rule group should be evaluated; default is 1 minute')
param ruleGroupInterval string = 'PT1M'

@description('The location where the rule group should be created')
param location string = resourceGroup().location

var clusterName = substring(scopeCluster, lastIndexOf(scopeCluster, '/') + 1)
var ruleGroupName = 'aioKpiRuleGroup_${ruleGroupPrefix}_${clusterName}'

@description('The name of the cluster parsed from the scopeCluster parameter')
output clusterName string = clusterName

@description('The name of the rule group created by this module')
output ruleGroupName string = ruleGroupName

@export()
@discriminator('ruleType')
type KpiRule = KpiHealthStateRollupRule | KpiHealthStateRule | KpiSignalRule

type KpiSignalRule = {
  ruleType: 'KpiSignal'
  outputMetric: string // Name of the output metric for the recording rule
  promQL: string // The Prom-QL query to generate the outputMetric
}

type KpiHealthStateRule = {
  ruleType: 'KpiHealthState'
  outputMetric: string // Name of the output metric for the recording rule
  promQL: string // The Prom-QL query to generate the outputMetric
  kpi: string // This is the hierarchy path for the health state KPI
}

type KpiHealthStateRollupRule = {
  ruleType: 'KpiHealthStateRollup'
  outputMetric: string // Name of the output metric for the recording rule
  promQL: string // The Prom-QL query to generate the outputMetric
  kpi: string // This is the hierarchy path for the rollup KPI
}

resource prometheusRuleGroup 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: ruleGroupName
  location: location
  properties: {
    enabled: true
    description: ruleGroupDescription
    clusterName: clusterName
    scopes: [
      scopeWorkspace
      scopeCluster
    ]
    rules: [
      for rule in rules : {
        record: rule.outputMetric
        enabled: true
        expression: trim(rule.promQL)
        labels: {
          job: ruleGroupName // used to identify the rule group in the output metric
          kpi: rule.?kpi ?? '.signal' // provides kpi hierarchy path for health state (signals which are not part of the health state hierarchy get the '.signal')
          rg: resourceGroup().name // used to identify the resource group the rule group is deployed in
        }
      }
    ]
    interval: ruleGroupInterval
  }
}
