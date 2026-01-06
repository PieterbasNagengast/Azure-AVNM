targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Description of the Azure Virtual Network Manager.')
param avnmDescription string

@description('Tags to be applied to all resources.')
param tags object

@description('Number of virtual networks to create for each type.')
param vnetCount int

@description('Array of static virtual networks to be added to the network group.')
param staticVvnets array

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

resource avnmNg 'Microsoft.Network/networkManagers/networkGroups@2025-01-01' = {
  name: 'myGrp'
  parent: avnm
  properties: {
    description: 'My group'
    memberType: 'VirtualNetwork'
  }
}

resource avnmNgStatic 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: staticVvnets[i].name
    parent: avnmNg
    properties: {
      resourceId: staticVvnets[i].id
    }
  }
]

output avnmId string = avnm.id
output avnmNgId string = avnmNg.id
