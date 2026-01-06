@description('Location for all resources.')
param location string

@description('Number of virtual networks to create for each type.')
param vnetCount int

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'HubVnet-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.255.0.0/24'
      ]
    }
  }
}

resource staticVvnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'StaticVNet${i}'
    location: location
    tags: {
      avnmManaged: 'false'
    }
    properties: {
      addressSpace: {
        addressPrefixes: [
          '10.0.${i}.0/24'
        ]
      }
    }
  }
]

resource dynamicVnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'DynamicVNet${i}'
    location: location
    tags: {
      avnmManaged: 'true'
    }
    properties: {
      addressSpace: {
        addressPrefixes: [
          '10.1.${i}.0/24'
        ]
      }
    }
  }
]

output hubVnetId string = hubVnet.id
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
