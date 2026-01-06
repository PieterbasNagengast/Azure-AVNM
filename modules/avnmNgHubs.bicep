@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Name of the AVNM Network Group.')
param avnmNgName string

@description('Number of virtual networks to create for each type.')
param hubVnets array

resource avnmNg 'Microsoft.Network/networkManagers/networkGroups@2025-01-01' = {
  name: '${avnmName}/${avnmNgName}'
  properties: {
    description: 'Network Group for Hub VNets'
    memberType: 'VirtualNetwork'
  }
}

resource avnmNgStatic 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2025-01-01' = [
  for hubVnet in hubVnets: {
    name: hubVnet.name
    parent: avnmNg
    properties: {
      resourceId: hubVnet.id
    }
  }
]
