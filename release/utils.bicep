/**********************************************************************************************
* This file provides utility functions, variables and internal types for building AIO 
* resources and deployments.
***********************************************************************************************/
import * as types from './types.bicep'

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

