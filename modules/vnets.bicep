@description('Location for all resources.')
param location string

@description('Number of virtual networks to create for each type.')
param vnetCount int

@description('CIDR block for the virtual networks in this region.')
param cidr string

// Deploy hub virtual network
resource hubVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'HubVnet-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        cidrSubnet(cidr, 24, 0)
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: cidrSubnet(cidrSubnet(cidr, 24, 0), 26, 0)
        }
      }
    ]
  }
}

// Deploy static virtual networks (static members of AVNM Network Group)
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

// Deploy dynamic virtual networks (dynamic members of AVNM Network Group)
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

output hubVnet object = {
  id: hubVnet.id
  name: hubVnet.name
}

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
