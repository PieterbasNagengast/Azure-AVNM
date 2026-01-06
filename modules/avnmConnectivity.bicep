@description('Name of the AVNM connectivity configuration.')
param connectivityConfigName string

@description('Indicates whether to use a hub gateway in the connectivity configuration.')
@allowed([
  'True'
  'False'
])
param useHubGateway string = 'False'

@description('Resource ID of the hub virtual network to be used in the connectivity configuration.')
param hubResourceId string

@description('Name of the Azure Virtual Network Manager Connectivity Configuration.')
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

resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

resource avnmConnectivity 'Microsoft.Network/networkManagers/connectivityConfigurations@2025-01-01' = {
  name: connectivityConfigName
  parent: avnm
  properties: {
    description: 'Connectivity configuration for AVNM Network Group ${networkGroupId}'
    appliesToGroups: [
      {
        groupConnectivity: groupConnectivity
        useHubGateway: useHubGateway
        networkGroupId: networkGroupId
      }
    ]
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
