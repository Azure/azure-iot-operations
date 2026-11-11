/**********************************************************************************************
* This file provides utility functions, variables and internal types for building AIO 
* resources and deployments.
***********************************************************************************************/
import * as types from './types.bicep'

@export()
@description('Use the supplied persistence configuration unchanged, or the recommended default for new deployments. Explicit opt-out takes precedence.')
func buildBrokerPersistence(enablePersistence bool, persistence types.BrokerPersistence?) types.BrokerPersistence? => !enablePersistence ? null : persistence ?? {
  maxSize: '3Gi'
  retain: {
    mode: 'None'
  }
  subscriberQueue: {
    mode: 'None'
  }
  stateStore: {
    mode: 'Custom'
    stateStoreSettings: {
      dynamic: {
        mode: 'Enabled'
      }
    }
  }
}

@discriminator('type')
type Identity = NoIdentity | UserAssignedIdentity

type NoIdentity = {
  type: 'None'
}
type UserAssignedIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: { *: {} }
}

@export()
@description('''
Builds a UserAssigned identity object for the given array of identities.
If the list is empty, it will return {type: 'None'}
e.g
```bicep
var identites = ['/subscriptions/.../id1', '/subscriptions/.../id2']
output userIdentities object = buildUserIdentities(identites)
// The output will be:
// {
//   "type": "UserAssigned",
//   "userAssignedIdentities": {
//     "/subscriptions/.../id1": {},
//     "/subscriptions/.../id2": {}
//   }
// }
}
''')
func buildIdentity(identities (string?)[]?) Identity => empty(identities) || length(filter(identities!, id => !empty(id))) == 0 ? {
  type: 'None'
} : {
  type: 'UserAssigned'
  userAssignedIdentities: toObject(filter(identities!, identity => !empty(identity)), identity => identity!, identity => {})
}

@export()
@description('Returns the default Role-based MCP authorization policy rules (aio-mcp-policy-v1).')
func mcpDefaultPolicies() object[] => [
  {
    action: 'ToolCall'
    principal: {
      principalType: 'Role'
      role: 'Reader'
    }
    resources: [
      'documentation_overview'
      'documentation'
      'list_edge_registry_groups'
      'get_edge_registry_group'
      'get_edge_registry_generic_resource'
      'get_edge_registry_resource'
      'list_edge_registry_resources'
      'list_edge_registry_resource_versions'
      'get_edge_registry_schema_from_asset'
      'list_assets'
      'get_asset'
      'asset_details'
      'list_devices'
      'get_device'
      'device_details'
      'list_connectors'
      'get_connector'
      'connector_details'
      'find_connector_by_device'
      'list_brokers'
      'get_broker'
      'broker_details'
      'list_dataflows'
      'get_dataflow'
      'dataflow_details'
      'list_dataflow_graphs'
      'get_dataflow_graph'
      'dataflow_graph_details'
    ]
  }
  {
    action: 'ToolCall'
    principal: {
      principalType: 'Role'
      role: 'DataReader'
    }
    resources: [
      'mq_messages'
      'dss_get'
    ]
  }
  {
    action: 'ToolCall'
    principal: {
      principalType: 'Role'
      role: 'Admin'
    }
    resources: [
      '*'
    ]
  }
]
