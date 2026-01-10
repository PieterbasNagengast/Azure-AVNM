@description('Location for all resources.')
param location string

@description('Number of virtual networks to create for each type.')
param vnetCount int

@description('CIDR block for the virtual networks in this region.')
param cidr string

@description('IPAM Pool IDs to be used for address space allocation. for static vnets and Hub vnet')
param ipamPool1Id string

@description('IPAM Pool IDs to be used for address space allocation. for dynamic vnets')
param ipamPool2Id string

@description('Tags to be applied to all resources.')
param tags object = {}

// Deploy hub virtual network
resource hubVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'HubVnet-${location}'
  location: location
  properties: {
    addressSpace: {
      ipamPoolPrefixAllocations: [
        {
          numberOfIpAddresses: '256'
          pool: {
            id: ipamPool1Id
          }
        }
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          ipamPoolPrefixAllocations: [
            {
              numberOfIpAddresses: '64'
              pool: {
                id: ipamPool1Id
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgHubVnet.id
          }
          routeTable: {
            id: udrHubVnet.id
          }
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          ipamPoolPrefixAllocations: [
            {
              numberOfIpAddresses: '64'
              pool: {
                id: ipamPool1Id
              }
            }
          ]
        }
      }
    ]
  }
  tags: tags
}

// Deploy NSG for hub virtual network
resource nsgHubVnet 'Microsoft.Network/networkSecurityGroups@2025-01-01' = {
  name: 'nsg-HubVnet-${location}'
  location: location
  properties: {}
  tags: tags
}

// Deploy UDR for hub virtual network
resource udrHubVnet 'Microsoft.Network/routeTables@2025-01-01' = {
  name: 'udr-HubVnet-${location}'
  location: location
  properties: {}
  tags: tags
}

// Deploy static virtual networks (static members of AVNM Network Group)
resource staticVvnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'StaticVNet${i}-${location}'
    location: location
    tags: union(tags, {
      avnmManaged: 'false'
    })
    properties: {
      addressSpace: {
        ipamPoolPrefixAllocations: [
          {
            numberOfIpAddresses: '256'
            pool: {
              id: ipamPool1Id
            }
          }
        ]
      }
      subnets: [
        {
          name: 'default'
          properties: {
            ipamPoolPrefixAllocations: [
              {
                numberOfIpAddresses: '64'
                pool: {
                  id: ipamPool1Id
                }
              }
            ]
            networkSecurityGroup: {
              id: nsgStaticVnets[i].id
            }
            routeTable: {
              id: udrsStaticVnets[i].id
            }
          }
        }
      ]
    }
  }
]

// Deploy NSGs for static virtual networks
resource nsgStaticVnets 'Microsoft.Network/networkSecurityGroups@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'nsg-StaticVNet${i}-${location}'
    location: location
    properties: {}
    tags: tags
  }
]

// Deploy UDRs for static virtual networks
resource udrsStaticVnets 'Microsoft.Network/routeTables@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'udr-StaticVNet${i}-${location}'
    location: location
    properties: {}
    tags: tags
  }
]

// Deploy dynamic virtual networks (dynamic members of AVNM Network Group)
resource dynamicVnets 'Microsoft.Network/virtualNetworks@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'DynamicVNet${i}-${location}'
    location: location
    tags: union(tags, {
      avnmManaged: 'true'
    })
    properties: {
      addressSpace: {
        ipamPoolPrefixAllocations: [
          {
            numberOfIpAddresses: '256'
            pool: {
              id: ipamPool2Id
            }
          }
        ]
      }
      subnets: [
        {
          name: 'default'
          properties: {
            ipamPoolPrefixAllocations: [
              {
                numberOfIpAddresses: '64'
                pool: {
                  id: ipamPool2Id
                }
              }
            ]
            networkSecurityGroup: {
              id: nsgDynamicVnets[i].id
            }
            routeTable: {
              id: udrsDynamicVnets[i].id
            }
          }
        }
      ]
    }
  }
]

// Deploy NSGs for dynamic virtual networks
resource nsgDynamicVnets 'Microsoft.Network/networkSecurityGroups@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'nsg-DynamicVNet${i}-${location}'
    location: location
    properties: {}
    tags: tags
  }
]

// Deploy UDRs for dynamic virtual networks
resource udrsDynamicVnets 'Microsoft.Network/routeTables@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'udr-DynamicVNet${i}-${location}'
    location: location
    properties: {}
    tags: tags
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

// Please read:
// Just fake output to mimic firewall IP address allocation (to be used as next hop address in AVNM routing config)
output AzFwIpAddress string = cidrHost(cidrSubnet(cidrSubnet(cidr, 24, 0), 26, 1), 4)
