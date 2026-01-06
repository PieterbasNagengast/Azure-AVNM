targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Description of the Azure Virtual Network Manager.')
param avnmDescription string

@description('Tags to be applied to all resources.')
param tags object

resource avnm 'Microsoft.Network/networkManagers@2025-01-01' = {
  name: avnmName
  location: location
  tags: tags
  properties: {
    description: avnmDescription
    networkManagerScopes: {
      subscriptions: [
        subscription().id
      ]
    }
    networkManagerScopeAccesses: [
      'Connectivity'
      'Routing'
      'SecurityAdmin'
    ]
  }
}

output avnmName string = avnm.name
output avnmId string = avnm.id
