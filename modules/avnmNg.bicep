@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Name of the AVNM Network Group.')
param avnmNgName string

@description('Array of objects respresenting VNET\'s Name and resource ID')
param Vnets _vnets

@description('Description of the AVNM Network Group.')
param avnmNgDescription string = 'AVNM Network Group'

type _vnets = {
  name: string
  id: string
}[]

@allowed([
  'VirtualNetwork'
  'Subnet'
])
param memberType string = 'VirtualNetwork'

resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

resource avnmNg 'Microsoft.Network/networkManagers/networkGroups@2025-01-01' = {
  name: avnmNgName
  parent: avnm
  properties: {
    description: avnmNgDescription
    memberType: memberType
  }
}

resource avnmNgStatic 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2025-01-01' = [
  for Vnet in Vnets: if (!empty(Vnets)) {
    name: Vnet.name
    parent: avnmNg
    properties: {
      resourceId: Vnet.id
    }
  }
]

output avnmNgId string = avnmNg.id
