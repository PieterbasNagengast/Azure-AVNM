@description('Location for all resources.')
param location string

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Number of virtual networks to create for each type.')
param vnetCount int = 3

@description('CIDR block for the virtual networks in this region.')
param cidr string

@description('Tags to be applied to all resources.')
param tags object = {}

// Deploy Azure Virtual Network ManagerNetwork Group
module avnmNg 'avnmNg.bicep' = {
  name: 'avnmNg-${location}'
  params: {
    avnmName: avnmName
    avnmNgDescription: 'Network Group for location ${location}'
    avnmNgName: 'NG-${location}'
    Vnets: vnets.outputs.staticVvnets
  }
}

// Deploy Policy Definition to dynamically add AVNM managed vnets to the network group
module avnmNgPolicyDef './avnmNgPolicyDef.bicep' = {
  name: 'avnmNgPolicyDef-${location}'
  scope: subscription()
  params: {
    networkGroupId: avnmNg.outputs.avnmNgId
  }
}

// Deploy Policy Assignment to assign the policy definition
module avnmNgPolicyAssign './avnmNgPolicyAssign.bicep' = {
  name: 'avnmNgPolicyAssign-${location}'
  params: {
    policyAssignName: 'Add-VNets-To-AVNM-Network-Group-${location}'
    policyLocation: location
    policyDefId: avnmNgPolicyDef.outputs.policyDefinitionId
    avnmNgName: avnmNg.name
  }
}

// Deploy bunch of virtual networks to be managed by AVNM
module vnets './vnets.bicep' = {
  name: 'vnets-${location}'
  params: {
    location: location
    vnetCount: vnetCount
    cidr: cidr
    ipamPool1Id: ipam.outputs.ipamPoolChild1Id
    ipamPool2Id: ipam.outputs.ipamPoolChild2Id
  }
}

// Deploy AVNM Connectivity Configuration to connect hub vnet to the network group
module avnmConnectivity './avnmConfigConnectivity.bicep' = {
  name: 'connectivity-${location}'
  params: {
    connectivityConfigName: 'ConnectivityConfig-${location}'
    hubResourceId: vnets.outputs.hubVnet.id
    networkGroupId: avnmNg.outputs.avnmNgId
    avnmName: avnmName
    deleteExistingPeering: 'True'
  }
}

// Deploy AVNM Routing Configuration to route traffic from the network group to the hub vnet
module avnmRouting './avnmConfigRouting.bicep' = {
  name: 'routing-${location}'
  params: {
    routingConfigName: 'RoutingConfig-${location}'
    networkGroupId: avnmNg.outputs.avnmNgId
    avnmName: avnmName
    nextHopAddress: vnets.outputs.AzFwIpAddress
  }
}

module ipam 'avnmIPAM.bicep' = {
  name: 'ipam-${location}'
  params: {
    location: location
    addressPrefixes: cidr
    avnmName: avnmName
    tags: tags
  }
}

output hubVnet object = vnets.outputs.hubVnet
output networkGroupId string = avnmNg.outputs.avnmNgId
