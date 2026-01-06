targetScope = 'subscription'

@description('Location for all resources.')
param location string = deployment().location

@description('Name of the Azure Virtual Network Manager.')
param avnmName string = 'AVNM01'

@description('Description of the Azure Virtual Network Manager.')
param avnmDescription string = 'Azure Virtual Network Manager'

@description('Tags to be applied to all resources.')
param tags object = {}

@description('Number of virtual networks to create for each type.')
param vnetCount int = 3

@description('Name of the resource group to deploy resources into.')
param rgName string = 'rg-avnm'

// Deploy resource group

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgName
  location: location
  tags: tags
}

// Deploy Azure Virtual Network Manager and Network Group

module avnm './modules/avnm.bicep' = {
  name: 'avnmDeployment'
  scope: rg
  params: {
    location: location
    avnmName: avnmName
    avnmDescription: avnmDescription
    tags: tags
    vnetCount: vnetCount
    staticVvnets: vnets.outputs.staticVvnets
  }
}

// Deploy Policy Definition to dynamically add AVNM managed vnets to the network group

module avnmNgPolicyDef './modules/avnmNgPolicyDef.bicep' = {
  name: 'avnmNgPolicyDefDeployment'
  scope: subscription()
  params: {
    networkGroupId: avnm.outputs.avnmNgId
  }
}

// Deploy Policy Assignment to assign the policy definition

module avnmNgPolicyAssign './modules/avnmNgPolicyAssign.bicep' = {
  name: 'avnmNgPolicyAssignDeployment'
  scope: rg
  params: {
    policyAssignName: 'Add-AVNM-Managed-VNets-To-Network-Group-Assignment'
    policyLocation: [
      location
    ]
    policyDefId: avnmNgPolicyDef.outputs.policyDefinitionId
  }
}

// Deploy bunch of virtual networks to be managed by AVNM

module vnets './modules/vnets.bicep' = {
  name: 'vnetsDeployment'
  scope: rg
  params: {
    location: location
    vnetCount: vnetCount
  }
}
