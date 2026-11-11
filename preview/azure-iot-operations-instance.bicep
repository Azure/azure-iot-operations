import * as types from './types.bicep'
import * as utils from './utils.bicep'

/*****************************************************************************/
/*                          Deployment Parameters                            */
/*****************************************************************************/

/*                          Cluster Parameters                               */
///////////////////////////////////////////////////////////////////////////////

@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param clusterName string

@description('The namespace on the cluster to deploy to.')
param clusterNamespace string = 'azure-iot-operations'

@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'westus3'
  'westeurope'
  'northeurope'
  'eastus2euap'
  'germanywestcentral'
  'southcentralus'
])
@description('Location of the existing arc-enabled cluster where AIO will be deployed.')
param clusterLocation string = any(resourceGroup().location)

/*                          Custom Location Parameters                       */
///////////////////////////////////////////////////////////////////////////////

@description('Name of the custom location where AIO will be deployed.')
param customLocationName string?

@description('List of cluster extension IDs for the custom location.')
param clExtensionIds string[]

/*                             Instance Parameters                           */
///////////////////////////////////////////////////////////////////////////////
@description('Name of the AIO instance to be created.')
param aioInstanceName string?

@description('User assigned identity resource id to assign to the AIO instance.')
param userAssignedIdentity string?

@description('Schema Registry Id used to reference the namespace to be passed in to the to be passed to Instance.')
param schemaRegistryId string

@description('Existing Azure Device Registry namespace resource ID to be passed in to the AIO Instance.')
param adrNamespaceId string?

@description('AIO Instance features. MCP defaults to Preview when omitted, including template redeployments; set mcp.mode to Disabled to opt out.')
param features types.Features?

@description('AIO Instance SKU name. Leave unset for the RP default.')
param sku ('Standard' | 'Essentials')?

/*                              Broker Parameters                            */
///////////////////////////////////////////////////////////////////////////////

@description('Configuration for the AIO Broker services deployed for AIO')
param brokerConfig types.BrokerConfig?

@description('''
Enable broker disk persistence for new deployments. Defaults to 3Gi per Backend replica (12Gi for two partitions with redundancy two) with retain/subscriber queue persistence disabled and dynamic state store persistence enabled, using the cluster default StorageClass.
When true, brokerConfig.persistence is used unchanged if supplied. Configure size/storage class there, or explicitly set false for clusters without suitable storage.
False overrides brokerConfig.persistence and provisions no persistence PVC: broker state, including schemas, is not durable and may be lost on restart.
For existing instances, use the upgrade flow; if redeploying this template, pass the existing persistence configuration (or false if nonpersistent) to avoid changing it.
''')
param enablePersistence bool = true

/*                                TLS Parameters                             */
///////////////////////////////////////////////////////////////////////////////

@description('Trust bundle config for AIO.')
param trustConfig types.TrustConfig = {
  source: 'SelfSigned'
}

/*                               Other Parameters                            */
///////////////////////////////////////////////////////////////////////////////

@description('Instance count for the default dataflow profile. The default is 1.')
param defaultDataflowInstanceCount int = 1

@description('Advanced Configuration for development')
param advancedConfig types.AdvancedConfig = {}

/*****************************************************************************/
/*                                Constants                                  */
/*****************************************************************************/

var VERSIONS = {
  iotOperations: '1.6.0-preview.60'
  connectors: '1.5.22'
}

var TRAINS = {
  iotOperations: 'preview'
}

/********************************************************************************/
/*                                Variables                                     */
/********************************************************************************/
var HASH = advancedConfig.?resourceSuffix ?? take(uniqueString(resourceGroup().id, clusterName, clusterNamespace), 5)
var AIO_EXTENSION_SUFFIX = take(uniqueString(cluster.id), 5)
var CUSTOM_LOCATION_NAMESPACE = clusterNamespace

var AIO_EXTENSION_SCOPE = {
  cluster: {
    releaseNamespace: clusterNamespace
  }
}
var customerManagedTrust = trustConfig.source == 'CustomerManaged'
var ISSUER_NAME = customerManagedTrust ? trustConfig.settings.issuerName : '${clusterNamespace}-aio-certificate-issuer'
var TRUST_CONFIG_MAP = customerManagedTrust
  ? trustConfig.settings.configMapName
  : '${clusterNamespace}-aio-ca-trust-bundle'
var TRUST_CONFIG_MAP_KEY = customerManagedTrust
  ? trustConfig.settings.configMapKey
  : 'ca.crt'

// OPC UA connector coordinates. These match the connectors chart shipped with this
// release. All four are overridable per-deployment via advancedConfig.
var OPCUA_CONNECTOR_VERSION = advancedConfig.?connectors.?version ?? VERSIONS.connectors
var CONNECTORS_CHART_REGISTRY = advancedConfig.?connectors.?registry ?? 'mcr.microsoft.com'
var CONNECTORS_CHART_REPOSITORY = advancedConfig.?connectors.?repository ?? 'azureiotoperations/aio-connectors/helmchart/microsoft-aio-connectors'
var CONNECTORS_IMAGE_REGISTRY = advancedConfig.?connectors.?imageRegistry ?? 'mcr.microsoft.com'

var MQTT_SETTINGS = {
  brokerListenerServiceName: 'aio-broker'
  brokerListenerPort: 18883
  brokerListenerHost: 'aio-broker.${CUSTOM_LOCATION_NAMESPACE}'
  serviceAccountAudience: 'aio-internal'
}

var BROKER_CONFIG = {
  frontendReplicas: brokerConfig.?frontendReplicas ?? 2
  frontendWorkers: brokerConfig.?frontendWorkers ?? 2
  backendRedundancyFactor: brokerConfig.?backendRedundancyFactor ?? 2
  backendWorkers: brokerConfig.?backendWorkers ?? 2
  backendPartitions: brokerConfig.?backendPartitions ?? 2
  memoryProfile: brokerConfig.?memoryProfile ?? 'Medium'
  serviceType: brokerConfig.?serviceType ?? 'ClusterIp'
  persistence: utils.buildBrokerPersistence(enablePersistence, brokerConfig.?persistence)
  diagnostics: brokerConfig.?diagnostics
}

/*****************************************************************************/
/*         Existing Arc-enabled cluster where AIO will be deployed.          */
/*****************************************************************************/

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

/*****************************************************************************/
/*                      Azure IoT Operations Meta Operator.                  */
/*****************************************************************************/

var defaultAioConfigurationSettings = {
  AgentOperationTimeoutInMinutes: '120'
  'connectors.image.tag': OPCUA_CONNECTOR_VERSION
  'connectors.image.registry': CONNECTORS_CHART_REGISTRY
  'connectors.image.repository': CONNECTORS_CHART_REPOSITORY
  'connectors.values.image.registry': CONNECTORS_IMAGE_REGISTRY
  'connectors.values.mqttBroker.address': 'mqtts://${MQTT_SETTINGS.brokerListenerHost}:${MQTT_SETTINGS.brokerListenerPort}'
  'connectors.values.mqttBroker.serviceAccountTokenAudience': MQTT_SETTINGS.serviceAccountAudience
  'connectors.values.securityPki.applicationUri': 'urn:microsoft.com:aio:opc:ua:broker:${AIO_EXTENSION_SUFFIX}'
  'connectors.values.securityPki.subjectName': 'CN=aio-opc-opcuabroker-${AIO_EXTENSION_SUFFIX}'

  'dataFlows.values.tinyKube.mqttBroker.hostName': MQTT_SETTINGS.brokerListenerHost
  'dataFlows.values.tinyKube.mqttBroker.port': MQTT_SETTINGS.brokerListenerPort
  'dataFlows.values.tinyKube.mqttBroker.authentication.serviceAccountTokenAudience': MQTT_SETTINGS.serviceAccountAudience
  'dataFlows.values.wasmGraphController.mqttBroker.caCertConfigMapRef': TRUST_CONFIG_MAP
  'dataFlows.values.wasmGraphController.mqttBroker.caCertFileName': TRUST_CONFIG_MAP_KEY

  'observability.metrics.enabled': '${advancedConfig.?observability.?enabled ?? false}'
  'observability.metrics.openTelemetryCollectorAddress': advancedConfig.?observability.?enabled ?? false
    ? '${advancedConfig.?observability.?otelCollectorAddress}'
    : ''

  trustSource: trustConfig.source
  'trustBundleSettings.issuer.name': ISSUER_NAME
  'trustBundleSettings.issuer.kind': trustConfig.?settings.?issuerKind ?? ''
  'trustBundleSettings.configMap.name': trustConfig.?settings.?configMapName ?? ''
  'trustBundleSettings.configMap.key': trustConfig.?settings.?configMapKey ?? ''

  'schemaRegistry.values.mqttBroker.host': 'mqtts://${MQTT_SETTINGS.brokerListenerHost}:${MQTT_SETTINGS.brokerListenerPort}'
  'schemaRegistry.values.mqttBroker.serviceAccountTokenAudience': MQTT_SETTINGS.serviceAccountAudience
}

resource aioExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: cluster
  name: 'azure-iot-operations-${AIO_EXTENSION_SUFFIX}'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.iotoperations'
    version: advancedConfig.?aio.?version ?? VERSIONS.iotOperations
    releaseTrain: advancedConfig.?aio.?train ?? TRAINS.iotOperations
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: union(
      defaultAioConfigurationSettings,
      advancedConfig.?aio.?configurationSettingsOverride ?? {}
    )
  }
}

/*****************************************************************************/
/*            Azure Arc Custom Location and Resource Sync Rules.             */
/*****************************************************************************/

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' = {
  name: customLocationName ?? 'location-${HASH}'
  location: clusterLocation
  properties: {
    hostResourceId: cluster.id
    namespace: clusterNamespace
    displayName: customLocationName ?? 'location-${HASH}'
    clusterExtensionIds: [...clExtensionIds, aioExtension.id]
  }
}

var extendedLocation = {
  name: customLocation.id
  type: 'CustomLocation'
}

/*****************************************************************************/
/*     Deployment of Helm Charts and CRs to run on Arc-enabled cluster.      */
/*****************************************************************************/

resource aioInstance 'Microsoft.IoTOperations/instances@2026-11-01-preview' = {
  name: aioInstanceName ?? 'aio-${HASH}'
  location: clusterLocation
  extendedLocation: extendedLocation
  identity: utils.buildIdentity([userAssignedIdentity])
  // sku stays null unless set; the generic envelope type flags that as BCP321
  #disable-next-line BCP321
  sku: sku != null ? { name: sku! } : null
  properties: {
    description: 'An AIO instance.'
    schemaRegistryRef: {
      resourceId: schemaRegistryId
    }
    features: union({
      mcp: {
        mode: 'Preview'
      }
    }, features ?? {})
    adrNamespaceRef: !empty(adrNamespaceId)
      ? {
          resourceId: adrNamespaceId!
        }
      : null
  }
}

/*****************************************************************************/
/*                             Broker Resources.                             */
/*****************************************************************************/

resource broker 'Microsoft.IoTOperations/instances/brokers@2026-11-01-preview' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: extendedLocation
  properties: {
    memoryProfile: BROKER_CONFIG.memoryProfile
    generateResourceLimits: {
      cpu: 'Disabled'
    }
    cardinality: {
      backendChain: {
        partitions: BROKER_CONFIG.backendPartitions
        workers: BROKER_CONFIG.backendWorkers
        redundancyFactor: BROKER_CONFIG.backendRedundancyFactor
      }
      frontend: {
        replicas: BROKER_CONFIG.frontendReplicas
        workers: BROKER_CONFIG.frontendWorkers
      }
    }
    persistence: BROKER_CONFIG.?persistence
    diagnostics: BROKER_CONFIG.?diagnostics
  }
}

resource brokerAuthn 'Microsoft.IoTOperations/instances/brokers/authentications@2026-11-01-preview' = {
  parent: broker
  name: 'default'
  extendedLocation: extendedLocation
  properties: {
    authenticationMethods: [
      {
        method: 'ServiceAccountToken'
        serviceAccountTokenSettings: {
          audiences: [
            MQTT_SETTINGS.serviceAccountAudience
          ]
        }
      }
    ]
  }
}

resource brokerListener 'Microsoft.IoTOperations/instances/brokers/listeners@2026-11-01-preview' = {
  parent: broker
  name: 'default'
  extendedLocation: extendedLocation
  properties: {
    serviceType: BROKER_CONFIG.serviceType
    serviceName: MQTT_SETTINGS.brokerListenerServiceName
    ports: [
      {
        authenticationRef: brokerAuthn.name
        port: MQTT_SETTINGS.brokerListenerPort
        tls: {
          mode: 'Automatic'
          certManagerCertificateSpec: {
            issuerRef: {
              name: ISSUER_NAME
              kind: customerManagedTrust ? trustConfig.settings.issuerKind : 'ClusterIssuer'
              group: 'cert-manager.io'
            }
          }
        }
      }
    ]
  }
}

/*****************************************************************************/
/*                             Dataflow Resources.                           */
/*****************************************************************************/

resource dataflowProfile 'Microsoft.IoTOperations/instances/dataflowProfiles@2026-11-01-preview' = {
  parent: aioInstance
  name: 'default'
  dependsOn: [
    broker
  ]
  extendedLocation: extendedLocation
  properties: {
    instanceCount: defaultDataflowInstanceCount
  }
}

resource dataflowEndpoint 'Microsoft.IoTOperations/instances/dataflowEndpoints@2026-11-01-preview' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: extendedLocation
  properties: {
    endpointType: 'Mqtt'
    mqttSettings: {
      host: '${MQTT_SETTINGS.brokerListenerHost}:${MQTT_SETTINGS.brokerListenerPort}'
      authentication: {
        method: 'ServiceAccountToken'
        serviceAccountTokenSettings: {
          audience: MQTT_SETTINGS.serviceAccountAudience
        }
      }
      tls: {
        mode: 'Enabled'
        trustedCaCertificateConfigMapRef: TRUST_CONFIG_MAP
      }
    }
  }
}

resource artifactRegistryEndpoint 'Microsoft.IoTOperations/instances/registryEndpoints@2026-11-01-preview' = {
  parent: aioInstance
  name: 'default'
  extendedLocation: extendedLocation
  properties: {
    host: 'mcr.microsoft.com'
    authentication: {
      method: 'Anonymous'
      anonymousSettings: {}
    }
  }
}

/*****************************************************************************/
/*                          Connector Templates.                             */
/*****************************************************************************/

// The OPC UA connector is supervisor-managed: the AIO extension maps this template
// to a ConnectorTemplate CR labelled 'aio-opc-supervisor', and the OPC UA supervisor
// (deployed by the connectors extension) creates the actual connector pods on demand.
// Per the connector metadata (AzureIoTOperationsOPCUAConnector), the connector image is
// the supervisor image, not the opcua-connector image.
//
// The name MUST start with 'azureiotoperationsconnectorforopcua-' so the OPC UA
// supervisor adopts this template. The supervisor only reconciles ConnectorTemplate CRs
// whose name matches that prefix (V1ConnectorTemplate.DefaultNamePrefix in the OPC UA
// connector repo); otherwise it never creates the child Connector for this template.
// A per-instance suffix mirrors the supervisor's generated name (e.g. '-e5c0').
var opcUaConnectorTemplateName = 'azureiotoperationsconnectorforopcua-${substring(uniqueString(aioInstance.id), 0, 4)}'

// Deployed regardless of the OPC UA feature mode. The AIO meta operator, not the supervisor,
// reports the ARM operation as Succeeded, so the template can exist while OPC UA is disabled
// and the supervisor picks it up once OPC UA is enabled through an instance update.
resource opcUaConnectorTemplate 'Microsoft.IoTOperations/instances/akriConnectorTemplates@2026-11-01-preview' = {
  parent: aioInstance
  name: opcUaConnectorTemplateName
  extendedLocation: extendedLocation
  properties: {
    connectorMetadataRef: 'mcr.microsoft.com/azureiotoperations/aio-connectors/opcua-metadata:${OPCUA_CONNECTOR_VERSION}'
    aioMetadata: {
      aioMinVersion: '1.2.100'
    }
    runtimeConfiguration: {
      runtimeConfigurationType: 'ManagedConfiguration'
      managedConfigurationSettings: {
        managedConfigurationType: 'ImageConfiguration'
        imageConfigurationSettings: {
          registrySettings: {
            registrySettingsType: 'ContainerRegistry'
            containerRegistrySettings: {
              registry: 'mcr.microsoft.com'
            }
          }
          imageName: 'azureiotoperations/aio-connectors/supervisor'
          tagDigestSettings: {
            tagDigestType: 'Tag'
            tag: OPCUA_CONNECTOR_VERSION
          }
        }
      }
    }
    deviceInboundEndpointTypes: [
      {
        endpointType: 'Microsoft.OpcUa'
      }
      {
        endpointType: 'Microsoft.OpcUa.WoT'
      }
    ]
  }
}

/*****************************************************************************/
/*                             MCP Resources.                                */
/*****************************************************************************/

resource mcpDefaultPolicy 'Microsoft.IoTOperations/instances/mcpAuthorizationPolicies@2026-11-01-preview' = {
  parent: aioInstance
  name: 'aio-mcp-policy-v1'
  extendedLocation: extendedLocation
  properties: {
    policies: utils.mcpDefaultPolicies()
  }
}

resource mcpAioConnection 'Microsoft.IoTOperations/instances/mcpServerConnections@2026-11-01-preview' = {
  parent: aioInstance
  name: 'aio'
  extendedLocation: extendedLocation
  properties: {
    service: {
      name: 'aio-mcp'
      path: '/mcp'
    }
    authorization: {
      mode: 'PolicyBased'
      policyRef: {
        name: mcpDefaultPolicy.name
      }
    }
  }
}

/*****************************************************************************/
/*                          Deployment Outputs                               */
/*****************************************************************************/

output aioExtension object = {
  name: aioExtension.name
  id: aioExtension.id
  version: aioExtension.properties.version
  releaseTrain: aioExtension.properties.releaseTrain
  config: {
    trustConfig: trustConfig
  }
  identityPrincipalId: aioExtension.identity.principalId
}

output aio object = {
  name: aioInstance.name
  broker: {
    name: broker.name
    listener: brokerListener.name
    authn: brokerAuthn.name
    settings: { ...BROKER_CONFIG, ...MQTT_SETTINGS }
  }
}

output customLocation object = {
  id: customLocation.id
  name: customLocation.name
}

output location string = clusterLocation
