import * as types from './types.bicep'

/*****************************************************************************/
/*                          Deployment Parameters                            */
/*****************************************************************************/

/*                          Cluster Parameters                               */
///////////////////////////////////////////////////////////////////////////////

@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param clusterName string

/*                                TLS Parameters                             */
///////////////////////////////////////////////////////////////////////////////

@description('Trust bundle config for AIO.')
param trustConfig types.TrustConfig = {
  source: 'SelfSigned'
}

/*                               Other Parameters                            */
///////////////////////////////////////////////////////////////////////////////

@description('Advanced Configuration for development')
param advancedConfig types.AdvancedConfig = {}

/*****************************************************************************/
/*                                Constants                                  */
/*****************************************************************************/

// Note: Do NOT update the keys of this object. The AIO Portal Wizard depends on the
// format of this object. Updating keys will break the UI.
var VERSIONS = {
  certManager: '1.0.0'
  secretStore: '1.5.2'
}

var TRAINS = {
  certManager: 'stable'
  secretStore: 'stable'
}

/*****************************************************************************/
/*         Existing Arc-enabled cluster where AIO will be deployed.          */
/*****************************************************************************/

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

/*****************************************************************************/
/*                      Azure IoT Operations Dependencies.                   */
/*****************************************************************************/

resource certManagerExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = if (trustConfig.source == 'SelfSigned') {
  scope: cluster
  name: 'cert-manager' // This is the enforced Managed Extension name for Cert Manager. Do not update.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.certmanagement'
    releaseTrain: advancedConfig.?certManager.?train ?? TRAINS.certManager
    version: advancedConfig.?certManager.?version ?? VERSIONS.certManager
    autoUpgradeMinorVersion: false
    scope: {
      cluster: {
        releaseNamespace: 'cert-manager'
      }
    }
    configurationSettings: {
      AgentOperationTimeoutInMinutes: '20'
      'global.telemetry.enabled': advancedConfig.?certManager.?telemetry.?enabled ?? 'true'
      'trust-manager.secretTargets.enabled': advancedConfig.?certManager.?secretTargets.?enabled ?? 'false'
      'trust-manager.secretTargets.authorizedSecretsAll': advancedConfig.?certManager.?secretTargets.?authorizedSecretsAll ?? 'false'
    }
  }
}

resource secretStoreExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  scope: cluster
  name: 'azure-secret-store' // This is the enforced Managed Extension name for SSC. Do not update.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.azure.secretstore'
    version: advancedConfig.?secretSyncController.?version ?? VERSIONS.secretStore
    releaseTrain: advancedConfig.?secretSyncController.?train ?? TRAINS.secretStore
    autoUpgradeMinorVersion: false
    configurationSettings: {
      rotationPollIntervalInSeconds: '120'
      'validatingAdmissionPolicies.applyPolicies': 'false'
    }
  }
  dependsOn: (trustConfig.source == 'SelfSigned') ? [ certManagerExtension ] : []
}

/*****************************************************************************/
/*                          Deployment Outputs                               */
/*****************************************************************************/

output clExtensionIds string[] = [
  secretStoreExtension.id
]

output extensions object = {
  certManager: {
    name: certManagerExtension.?name
    id: certManagerExtension.?id
    version: certManagerExtension.?properties.version
    releaseTrain: certManagerExtension.?properties.releaseTrain
  }
  secretStore: {
    name: secretStoreExtension.name
    id: secretStoreExtension.id
    version: secretStoreExtension.properties.version
    releaseTrain: secretStoreExtension.properties.releaseTrain
  }
}
