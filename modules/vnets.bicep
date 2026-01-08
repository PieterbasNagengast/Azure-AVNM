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
          addressPrefix: cidrSubnet(cidrSubnet(cidr, 24, 0), 26, 1)
        }
      }
    ]
  }
}

// Deploy NSG for hub virtual network
resource nsgHubVnet 'Microsoft.Network/networkSecurityGroups@2025-01-01' = {
  name: 'nsg-HubVnet-${location}'
  location: location
  properties: {}
}

// Deploy UDR for hub virtual network
resource udrHubVnet 'Microsoft.Network/routeTables@2025-01-01' = {
  name: 'udr-HubVnet-${location}'
  location: location
  properties: {}
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
      subnets: [
        {
          name: 'default'
          properties: {
            addressPrefix: cidrSubnet(cidrSubnet(cidr, 24, i + 1), 26, 0)
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
  }
]

// Deploy UDRs for static virtual networks
resource udrsStaticVnets 'Microsoft.Network/routeTables@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'udr-StaticVNet${i}-${location}'
    location: location
    properties: {}
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
      subnets: [
        {
          name: 'default'
          properties: {
            addressPrefix: cidrSubnet(cidrSubnet(cidr, 24, i + 1 + vnetCount), 26, 0)
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
  }
]

// Deploy UDRs for dynamic virtual networks
resource udrsDynamicVnets 'Microsoft.Network/routeTables@2025-01-01' = [
  for i in range(0, vnetCount): {
    name: 'udr-DynamicVNet${i}-${location}'
    location: location
    properties: {}
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
