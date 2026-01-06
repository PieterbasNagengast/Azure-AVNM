@description('Location for all resources.')
param location string

@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Number of virtual networks to create for each type.')
param vnetCount int = 3

// Deploy Azure Virtual Network ManagerNetwork Group

module avnmNg 'avnmNg.bicep' = {
  name: 'avnmNg-${location}'
  params: {
    avnmName: avnmName
    avnmNgName: 'NG-${location}'
    vnetCount: vnetCount
    staticVvnets: vnets.outputs.staticVvnets
    location: location
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
  }
}

// Deploy AVNM Connectivity Configuration to connect hub vnet to the network group

module avnmConnectivity './avnmConnectivity.bicep' = {
  name: 'connectivity-${location}'
  params: {
    connectivityConfigName: 'ConnectivityConfig-${location}'
    hubResourceId: vnets.outputs.hubVnetId
    networkGroupId: avnmNg.outputs.avnmNgId
    avnmName: avnmName
  }
}

output hubVnet object = {
  id: vnets.outputs.hubVnetId
  name: vnets.outputs.hubVnetName
}
