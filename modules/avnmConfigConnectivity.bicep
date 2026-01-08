@description('Name of the AVNM connectivity configuration.')
param connectivityConfigName string

@description('Indicates whether to use a hub gateway in the connectivity configuration.')
@allowed([
  'True'
  'False'
])
param useHubGateway string = 'False'

@description('Resource ID of the hub virtual network to be used in the connectivity configuration.')
param hubResourceId string = ''

@description('ResourceID of the Network group to be associated with the connectivity configuration.')
param networkGroupId string

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Group connectivity type for the AVNM connectivity configuration.')
@allowed([
  'None'
  'DirectlyConnected'
])
param groupConnectivity string = 'None'

@allowed([
  'True'
  'False'
])
param deleteExistingPeering string = 'False'

@description('Connectivity topology for the AVNM connectivity configuration.')
@allowed([
  'HubAndSpoke'
  'Mesh'
])
param connectivitytopology string = 'HubAndSpoke'

@description('Peering enforcement setting for the AVNM connectivity configuration.')
@allowed([
  'Enforced'
  'Unenforced'
])
param peeringEnforcement string = 'Enforced'

@description('Address overlap setting for private endpoints in the connected group.')
@allowed([
  'Allowed'
  'Disallowed'
])
param connectedGroupAddressOverlap string = 'Disallowed'

@description('Scale setting for private endpoints in the connected group.')
@allowed([
  'Standard'
  'HighScale'
])
param connectedGroupPrivateEndpointsScale string = 'Standard'

// avnm existing resource
resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

// AVNM Connectivity Configuration resource
resource avnmConnectivity 'Microsoft.Network/networkManagers/connectivityConfigurations@2025-01-01' = {
  name: connectivityConfigName
  parent: avnm
  properties: {
    description: 'Connectivity configuration for AVNM Network Group'
    appliesToGroups: [
      {
        groupConnectivity: groupConnectivity
        useHubGateway: useHubGateway
        networkGroupId: networkGroupId
      }
    ]
    connectivityCapabilities: {
      connectedGroupPrivateEndpointsScale: connectedGroupPrivateEndpointsScale
      connectedGroupAddressOverlap: connectedGroupAddressOverlap
      peeringEnforcement: connectivitytopology == 'Mesh' ? 'Unenforced' : peeringEnforcement
    }
    isGlobal: connectivitytopology == 'Mesh' ? 'True' : 'False'
    connectivityTopology: connectivitytopology
    deleteExistingPeering: deleteExistingPeering
    hubs: connectivitytopology == 'HubAndSpoke'
      ? [
          {
            resourceId: hubResourceId
            resourceType: 'Microsoft.Network/virtualNetworks'
          }
        ]
      : []
  }
}
