@export()
type AdvancedConfig = {
  platform: {
    version: string?
    train: string?
  }?
  certManager: {
    version: string?
    train: string?
    telemetry: {
      enabled: string?
    }?
  }?
  aio: {
    version: string?
    train: string?
    configurationSettingsOverride: object?
  }?
  secretSyncController: {
    version: string?
    train: string?
  }?
  observability: {
    enabled: bool?
    otelCollectorAddress: string?
    otelExportIntervalSeconds: int?
  }?
  openServiceMesh: {
    version: string?
    train: string?
  }?
  edgeStorageAccelerator: {
    version: string?
    train: string?
    // The Kubernetes storage class used when storing Schemas
    diskStorageClass: string?
    faultToleranceEnabled: bool?
    diskMountPoint: string?
  }?
  resourceSuffix: string?
}

@export()
@discriminator('source')
type TrustConfig = SelfSigned | CustomerManaged

type SelfSigned = {
  source: 'SelfSigned'
}

type CustomerManaged = {
  source: 'CustomerManaged'
  settings: TrustBundleSettings
}

type TrustBundleSettings = {
  issuerName: string
  issuerKind: 'ClusterIssuer' | 'Issuer'
  configMapName: string
  configMapKey: string
}

@export()
type BrokerConfig = {
  @minValue(1)
  @maxValue(16)
  @description('Number of AIO Broker frontend replicas. The default is 2.')
  frontendReplicas: int?

  @minValue(1)
  @maxValue(16)
  @description('Number of AIO Broker frontend workers. The default is 2.')
  frontendWorkers: int?

  @minValue(1)
  @maxValue(5)
  @description('The AIO Broker backend redundancy factory. The default is 2.')
  backendRedundancyFactor: int?

  @minValue(1)
  @maxValue(16)
  @description('Number of AIO Broker backend workers. The default is 2.')
  backendWorkers: int?

  @minValue(1)
  @maxValue(16)
  @description('Number of AIO Broker backend partitions. The default is 2.')
  backendPartitions: int?

  @description('The AIO Broker memory profile. The default is "Medium".')
  memoryProfile: 'Tiny' | 'Low' | 'Medium' | 'High' | null

  @description('The AIO Broker service type. The default is "ClusterIp".')
  serviceType: 'ClusterIp' | 'LoadBalancer' | 'NodePort' | null

  @description('The persistence settings of the Broker.')
  persistence: BrokerPersistence?

  @description('The AIO Broker diagnostics settings.')
  diagnostics: BrokerDiagnostics?
}

@description('AIO Instance features.')
@export()
type Features = {
  @description('Object of features')
  *: InstanceFeature
}

@description('Individual feature object within the AIO instance.')
type InstanceFeature = {
  mode: InstanceFeatureMode?
  settings: {
    *: InstanceFeatureSettingValue
  }
}

@description('The mode of the AIO instance feature. Either "Stable", "Preview" or "Disabled".')
type InstanceFeatureMode = 'Stable' | 'Preview' | 'Disabled'

@description('The setting value of the AIO instance feature. Either "Enabled" or "Disabled".')
type InstanceFeatureSettingValue = OperationalMode

@description('Defines operational mode. Either "Enabled" or "Disabled".')
type OperationalMode = 'Enabled' | 'Disabled'

@description('Defines the diagnostics settings for the Broker CRD.')
type BrokerDiagnostics = {
  @description('The log settings of the broker.')
  logs: {
    @description('The log level. Examples - "debug", "info", "warn", "error", "trace".')
    level: string?
  }?

  @description('The metrics properties.')
  metrics: {
    @description('The prometheus port to expose the metrics.')
    prometheusPort: int?
  }?

  @description('The self check properties.')
  selfCheck: {
    @description('The toggle to enable/disable self check. Allowed values: "Enabled", "enabled", "Disabled", "disabled".')
    mode: OperationalMode?

    @description('The self check interval in seconds.')
    intervalSeconds: int?

    @description('The timeout for self check in seconds.')
    timeoutSeconds: int?
  }?

  @description('The trace properties.')
  traces: {
    @description('The toggle to enable/disable traces. Allowed values: "Enabled", "enabled", "Disabled", "disabled".')
    mode: OperationalMode?

    @description('The cache size in megabytes.')
    cacheSizeMegabytes: int?

    @description('The self tracing properties.')
    selfTracing: {
      @description('The toggle to enable/disable self tracing. Allowed values: "Enabled", "enabled", "Disabled", "disabled".')
      mode: OperationalMode?

      @description('The self tracing interval in seconds.')
      intervalSeconds: int?
    }?

    @description('The span channel capacity.')
    spanChannelCapacity: int?
  }?
}

@description('''
Disk persistence configuration for the Broker.
Optional. Everything is in-memory if not set.
Note: if configured, all MQTT session states are written to disk.
''')
type BrokerPersistence = {
  @description('''
The max size of the message buffer on disk. If a PVC template is specified, this size
is used as the request and limit sizes of that template. If unset, a local-path provisioner is used.
''')
  maxSize: string

  @description('''
Use the specified PersistentVolumeClaim template to mount a persistent volume.
If unset, a default PVC with default properties will be used.
''')
  persistentVolumeClaimSpec: VolumeClaimSpec?

  @description('''Controls which topic's retained messages should be persisted to disk.''')
  retain: BrokerRetainMessagesPolicy?

  @description('Controls which keys should be persisted to disk for the state store.')
  stateStore: BrokerStateStorePolicy?

  @description('''
Controls which subscriber message queues should be persisted to disk.
Session state metadata are always written to disk if any persistence is specified.
''')
  subscriberQueue: BrokerSubscriberQueuePolicy?

  @description('''
Controls settings related to encryption of the persistence database.
Optional, defaults to enabling encryption.
''')
  encryption: BrokerPersistenceEncryption?
}

@description('Encryption settings for the persistence database.')
type BrokerPersistenceEncryption = {
  @description('Determines if encryption is enabled.')
  mode: OperationalMode
}

@description('Kubernetes PersistentVolumeClaim spec.')
type VolumeClaimSpec = {
  volumeName: string?
  volumeMode: string?
  storageClassName: string?
  accessModes: string[]?
  dataSource: object?
  dataSourceRef: object?
  resources: object?
  selector: object?
}

@description('Controls which retained messages are persisted.')
@discriminator('mode')
type BrokerRetainMessagesPolicy = { mode: 'All' } | { mode: 'None' } | BrokerRetainMessagesCustomPolicy

@description('Custom retain messages policy for the Broker.')
type BrokerRetainMessagesCustomPolicy = {
  mode: 'Custom'

  @description('Settings for the Custom mode.')
  retainSettings: BrokerRetainMessagesSettings
}

@description('Settings for a custom retain messages policy.')
type BrokerRetainMessagesSettings = {
  @description('Topics to persist (wildcards # and + supported).')
  topics: string[]?

  @description('Dynamic toggle via MQTTv5 user property.')
  dynamic: BrokerRetainMessagesDynamic?
}

@description('Dynamic toggles for retain messages policy.')
type BrokerRetainMessagesDynamic = {
  @description('Mode of dynamic retain settings.')
  mode: OperationalMode
}

@description('Controls which state store entries are persisted.')
@discriminator('mode')
type BrokerStateStorePolicy = { mode: 'All' } | { mode: 'None' } | BrokerStateStoreCustomPolicy

@description('Custom state store policy for the Broker.')
type BrokerStateStoreCustomPolicy = {
  mode: 'Custom'

  @description('Settings for the Custom mode.')
  stateStoreSettings: BrokerStateStorePolicySettings
}

@description('Settings for a custom state store policy.')
type BrokerStateStorePolicySettings = {
  @description('Resources to persist (keyType and list of keys).')
  stateStoreResources: BrokerStateStorePolicyResources[]?

  @description('Dynamic toggle via MQTTv5 user property.')
  dynamic: BrokerStateStoreDynamic?
}

@description('A key-type and its associated keys for state store persistence.')
type BrokerStateStorePolicyResources = {
  @description('Type of key matching.')
  keyType: 'Pattern' | 'String' | 'Binary'

  @description('List of keys to persist.')
  keys: string[]
}

@description('Dynamic toggles for state store policy.')
type BrokerStateStoreDynamic = {
  @description('Mode of dynamic state store settings.')
  mode: OperationalMode
}

@description('Controls which subscriber queues are persisted.')
@discriminator('mode')
type BrokerSubscriberQueuePolicy = { mode: 'All' } | { mode: 'None' } | BrokerSubscriberQueueCustomPolicy

type BrokerSubscriberQueueCustomPolicy = {
  mode: 'Custom'

  @description('Settings for the Custom mode.')
  subscriberQueueSettings: BrokerSubscriberQueueCustomPolicySettings
}

@description('Settings for a custom subscriber queue policy.')
type BrokerSubscriberQueueCustomPolicySettings = {
  @description('Subscriber client IDs to persist (wildcard * supported).')
  subscriberClientIds: string[]?

  @description('Dynamic toggle via MQTTv5 user property.')
  dynamic: BrokerSubscriberQueueDynamic?
}

@description('Dynamic toggles for subscriber queue policy.')
type BrokerSubscriberQueueDynamic = {
  @description('Mode of dynamic subscriber queue settings.')
  mode: OperationalMode
}
