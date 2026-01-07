@description('Location for all resources.')
param location string

@description('Number of virtual networks to create for each type.')
param vnetCount int

@description('CIDR block for the virtual networks in this region.')
param cidr string

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'HubVnet-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        cidrSubnet(cidr, 24, 0)
      ]
    }
  }
}

resource staticVvnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'StaticVNet${i}-${location}'
    location: location
    tags: {
      avnmManaged: 'false'
    }
    properties: {
      addressSpace: {
        addressPrefixes: [
          cidrSubnet(cidr, 24, i + 1)
        ]
      }
    }
  }
]

resource dynamicVnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'DynamicVNet${i}-${location}'
    location: location
    tags: {
      avnmManaged: 'true'
    }
    properties: {
      addressSpace: {
        addressPrefixes: [
          cidrSubnet(cidr, 24, i + 1 + vnetCount)
        ]
      }
    }
  }
]

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output staticVvnets array = [
  for i in range(0, vnetCount): {
    id: staticVvnets[i].id
    name: staticVvnets[i].name
  }
]
output dynamicVnets array = [
  for i in range(0, vnetCount): {
    id: dynamicVnets[i].id
    name: dynamicVnets[i].name
  }
]
