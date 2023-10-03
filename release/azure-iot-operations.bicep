metadata description = 'This template deploys Azure IoT Operations.'

/*****************************************************************************/
/*                          Deployment Parameters                            */
/*****************************************************************************/

param clusterName string

@allowed([
  'eastus2'
  'westus3'
  'westeurope'
])
param clusterLocation string = location

param location string = resourceGroup().location

param customLocationName string = '${clusterName}-cl'

param simulatePLC bool = false

param opcuaDiscoveryEndpoint string = 'opc.tcp://<NOT_SET>:<NOT_SET>'

param bluefinSecrets object = {
  enabled: false
  secretProviderClassName: ''
  servicePrincipalSecretRef: ''
}

param e4kSecrets object = {
  enabled: false
  secretProviderClassName: ''
  servicePrincipalSecretRef: ''
}

param opcBrokerSecrets object = {
  enabled: false
  secretProviderClassName: ''
  servicePrincipalSecretRef: ''
}

var akri = {
  opcUaDiscoveryDetails: 'opcuaDiscoveryMethod:\n  - asset:\n      endpointUrl: "${opcuaDiscoveryEndpoint}"\n      useSecurity: false\n      autoAcceptUntrustedCertificates: true\n      userName: "user1"\n      password: "password"  \n'
}

/*****************************************************************************/
/*                                Constants                                  */
/*****************************************************************************/

var AIO_CLUSTER_RELEASE_NAMESPACE = 'azure-iot-operations'

var AIO_CLUSTER_RESOURCE_NAMESPACE = 'azure-iot-operations-solution'

var AIO_EXTENSION_SCOPE = {
  cluster: {
    releaseNamespace: AIO_CLUSTER_RELEASE_NAMESPACE
  }
}

var OBSERVABILITY = {
  genevaCollectorAddressNoProtocol: 'geneva-metrics-service.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
  otelCollectorAddressNoProtocol: 'otel-collector.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
}

/*****************************************************************************/
/*         Existing Arc-enabled cluster where AIO will be deployed.          */
/*****************************************************************************/

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

/*****************************************************************************/
/*                     Azure IoT Operations Extensions.                      */
/*****************************************************************************/

resource orchestrator_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'azure-iot-operations'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.alicesprings'
    version: '0.45.1'
    releaseTrain: 'private-preview'
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'Microsoft.CustomLocation.ServiceAccount': 'default'
      otelCollectorAddress: OBSERVABILITY.otelCollectorAddressNoProtocol
      genevaCollectorAddress: OBSERVABILITY.genevaCollectorAddressNoProtocol
    }
  }
}

resource deviceRegistry_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'assets'
  properties: {
    extensionType: 'microsoft.deviceregistry.assets'
    version: '0.10.0'
    releaseTrain: 'private-preview'
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {}
  }
}

resource mq_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'mq'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.alicesprings.dataplane'
    version: '0.6.0-rc4'
    releaseTrain: 'private-preview'
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'global.quickstart': true
      'global.openTelemetryCollectorAddr': 'http://${OBSERVABILITY.otelCollectorAddressNoProtocol}'
    }
  }
}

resource dataProcessor_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'processor'
  properties: {
    extensionType: 'microsoft.alicesprings.processor'
    version: '0.2.6'
    releaseTrain: 'private-preview'
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'Microsoft.CustomLocation.ServiceAccount': 'default'
      otelCollectorAddress: OBSERVABILITY.otelCollectorAddressNoProtocol
      genevaCollectorAddress: OBSERVABILITY.genevaCollectorAddressNoProtocol
      tracePodFormat: 'OFF'
      'bluefin.secrets.enabled': bluefinSecrets.enabled
      'bluefin.secrets.secretProviderClassName': bluefinSecrets.secretProviderClassName
      'bluefin.secrets.servicePrincipalSecretRef': bluefinSecrets.servicePrincipalSecretRef
    }
  }
}

resource akri_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'akri'
  properties: {
    extensionType: 'microsoft.akri'
    version: '0.2.0-rc1'
    releaseTrain: 'private-preview'
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'webhookConfiguration.enabled': false
    }
  }
}

/*****************************************************************************/
/*            Azure Arc custom location and resource sync rules.             */
/*****************************************************************************/

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' = {
  name: customLocationName
  location: clusterLocation
  properties: {
    hostResourceId: cluster.id
    namespace: AIO_CLUSTER_RESOURCE_NAMESPACE
    displayName: customLocationName
    clusterExtensionIds: [
      orchestrator_extension.id
      deviceRegistry_extension.id
      dataProcessor_extension.id
      akri_extension.id
    ]
  }
}

resource orchestrator_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = {
  parent: customLocation
  name: '${customLocationName}-aio-sync'
  location: clusterLocation
  properties: {
    priority: 100
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.symphony'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
}

resource deviceRegistry_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = {
  parent: customLocation
  name: '${customLocationName}-adr-sync'
  location: clusterLocation
  properties: {
    priority: 200
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'Microsoft.DeviceRegistry'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
}

resource dataProcessor_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = {
  parent: customLocation
  name: '${customLocationName}-dp-sync'
  location: clusterLocation
  properties: {
    priority: 300
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.bluefin'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
}

/*****************************************************************************/
/*               Azure IoT Operations Data Processor Instance.               */
/*****************************************************************************/

resource processorInstance 'Microsoft.Bluefin/instances@2023-06-26-preview' = {
  name: '${clusterName}-processor'
  location: location
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {}
}

/*****************************************************************************/
/*     Deployment of Helm Charts and CRs to run on Arc-enabled cluster.      */
/*****************************************************************************/

var observability_helmChart = {
  name: 'observability'
  type: 'helm.v3'
  properties: {
    chart: {
      repo: 'alicesprings.azurecr.io/helm/opentelemetry-collector'
      version: '0.62.3'
    }
    values: {
      mode: 'deployment'
      fullnameOverride: 'otel-collector'
      config: {
        receivers: {
          otlp: {
            protocols: {
              grpc: {
                endpoint: ':4317'
              }
              http: {
                endpoint: ':4318'
              }
            }
          }
        }
        exporters: {
          prometheus: {
            endpoint: ':8889'
            resource_to_telemetry_conversion: {
              enabled: true
            }
          }
        }
        service: {
          pipelines: {
            metrics: {
              receivers: [
                'otlp'
              ]
              exporters: [
                'prometheus'
              ]
            }
            logs: null
          }
        }
      }
      ports: {
        metrics: {
          enabled: true
          containerPort: 8889
          servicePort: 8889
          protocol: 'TCP'
        }
        'jaeger-compact': {
          enabled: false
        }
        'jaeger-grpc': {
          enabled: false
        }
        'jaeger-thrift': {
          enabled: false
        }
        zipkin: {
          enabled: false
        }
      }
    }
  }
}

var layeredNetworking_helmChart = {
  name: 'layered-networking'
  type: 'helm.v3'
  properties: {
    chart: {
      repo: 'alicesprings.azurecr.io/az-e4in'
      version: '0.1.2'
    }
  }
}

var opcUaBroker_helmChart = {
  name: 'opc-ua-broker'
  type: 'helm.v3'
  properties: {
    chart: {
      repo: 'alicesprings.azurecr.io/helm/az-e4i'
      version: '0.7.0'
    }
    values: {
      mqttBroker: {
        authenticationMethod: 'serviceAccountToken'
        name: 'azedge-dmqtt-frontend'
        namespace: AIO_CLUSTER_RELEASE_NAMESPACE
      }
      opcPlcSimulation: {
        deploy: simulatePLC
      }
      openTelemetry: {
        enabled: true
        endpoints: {
          default: {
            uri: 'http://${OBSERVABILITY.otelCollectorAddressNoProtocol}'
            protocol: 'grpc'
            emitLogs: false
            emitMetrics: true
            emitTraces: false
          }
          geneva: {
            uri: 'http://${OBSERVABILITY.genevaCollectorAddressNoProtocol}'
            protocol: 'grpc'
            emitLogs: false
            emitMetrics: true
            emitTraces: false
          }
        }
      }
    }
  }
}

var akri_daemonset = {
  name: 'akri-opcua-asset-discovery-daemonset'
  type: 'yaml.k8s'
  properties: {
    resource: {
      apiVersion: 'apps/v1'
      kind: 'DaemonSet'
      metadata: {
        name: 'akri-opcua-asset-discovery-daemonset'
      }
      spec: {
        selector: {
          matchLabels: {
            name: 'akri-opcua-asset-discovery'
          }
        }
        template: {
          metadata: {
            labels: {
              name: 'akri-opcua-asset-discovery'
            }
          }
          spec: {
            containers: [
              {
                name: 'akri-opcua-asset-discovery'
                image: 'e4ipreview.azurecr.io/e4i/workload/akri-opc-ua-asset-discovery:latest'
                imagePullPolicy: 'Always'
                resources: {
                  requests: {
                    memory: '64Mi'
                    cpu: '10m'
                  }
                  limits: {
                    memory: '512Mi'
                    cpu: '100m'
                  }
                }
                ports: [
                  {
                    name: 'discovery'
                    containerPort: 80
                  }
                ]
                env: [
                  {
                    name: 'POD_IP'
                    valueFrom: {
                      fieldRef: {
                        fieldPath: 'status.podIP'
                      }
                    }
                  }
                  {
                    name: 'DISCOVERY_HANDLERS_DIRECTORY'
                    value: '/var/lib/akri'
                  }
                ]
                volumeMounts: [
                  {
                    name: 'discovery-handlers'
                    mountPath: '/var/lib/akri'
                  }
                ]
              }
            ]
            volumes: [
              {
                name: 'discovery-handlers'
                hostPath: {
                  path: '/var/lib/akri'
                }
              }
            ]
          }
        }
      }
    }
  }
}

var asset_configuration = {
  name: 'akri-opcua-asset'
  type: 'yaml.k8s'
  properties: {
    resource: {
      apiVersion: 'akri.sh/v0'
      kind: 'Configuration'
      metadata: {
        name: 'akri-opcua-asset'
      }
      spec: {
        discoveryHandler: {
          name: 'opcua-asset'
          discoveryDetails: akri.opcUaDiscoveryDetails
        }
        brokerProperties: {}
        capacity: 1
      }
    }
  }
}

resource target 'Microsoft.Symphony/targets@2023-05-22-preview' = {
  name: '${clusterName}-target'
  location: location
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    scope: AIO_CLUSTER_RELEASE_NAMESPACE
    version: deployment().properties.template.contentVersion
    components: [
      observability_helmChart
      layeredNetworking_helmChart
      opcUaBroker_helmChart
      akri_daemonset
      asset_configuration
    ]
    topologies: [
      {
        bindings: [
          {
            role: 'instance'
            provider: 'providers.target.k8s'
            config: {
              inCluster: 'true'
            }
          }
          {
            role: 'helm.v3'
            provider: 'providers.target.helm'
            config: {
              inCluster: 'true'
            }
          }
          {
            role: 'yaml.k8s'
            provider: 'providers.target.kubectl'
            config: {
              inCluster: 'true'
            }
          }
        ]
      }
    ]
  }
}

output customLocationId string = customLocation.id
