@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Name of the AVNM Network Group.')
param avnmNgName string

@description('Number of virtual networks to create for each type.')
param vnetCount int

@description('Array of static virtual networks to be added to the network group.')
param staticVvnets array

@description('Location for all resources.')
param location string

resource avnmNg 'Microsoft.Network/networkManagers/networkGroups@2025-01-01' = {
  name: '${avnmName}/${avnmNgName}'
  properties: {
    description: 'Spoke Network Group for location ${location}'
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

output avnmNgId string = avnmNg.id
