@description('Name of the AVNM routing configuration.')
param routingConfigName string

@description('ResourceID of the Network group to be associated with the routing configuration.')
param networkGroupId string

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@allowed([
  'ManagedOnly'
  'UseExisting'
])
param routeTableUsageMode string = 'UseExisting'

@allowed([
  'True'
  'False'
])
param disableBgpRoutePropagation string = 'False'

param nextHopAddress string

// avnm existing resource
resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

// AVNM Routing Configuration resource
resource avnmRouting 'Microsoft.Network/networkManagers/routingConfigurations@2025-01-01' = {
  name: routingConfigName
  parent: avnm
  properties: {
    description: 'Routing configuration for AVNM Network Group'
    routeTableUsageMode: routeTableUsageMode
  }
}

// AVNM Routing Rule Collection resource
resource avnmRoutingRuleCollections 'Microsoft.Network/networkManagers/routingConfigurations/ruleCollections@2025-01-01' = {
  name: 'DefaultRouteCollection'
  parent: avnmRouting
  properties: {
    description: 'Default route collection'
    appliesTo: [
      {
        networkGroupId: networkGroupId
      }
    ]
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

// AVNM Routing Rule resource
resource avnmRoutingRules 'Microsoft.Network/networkManagers/routingConfigurations/ruleCollections/rules@2025-01-01' = {
  name: 'DefaultRoute'
  parent: avnmRoutingRuleCollections
  properties: {
    description: 'Default route to virtual appliance'
    destination: {
      destinationAddress: '0.0.0.0/0'
      type: 'AddressPrefix'
    }
    nextHop: {
      nextHopType: 'VirtualAppliance'
      nextHopAddress: nextHopAddress
    }
  }
}
