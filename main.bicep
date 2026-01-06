targetScope = 'subscription'

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

param locations array = [
  'swedencentral'
  'germanywestcentral'
]

// Deploy resource group

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgName
  location: locations[0]
  tags: tags
}

// Deploy Azure Virtual Network Manager and Network Group

module avnm './modules/avnm.bicep' = {
  name: 'avnmDeployment'
  scope: rg
  params: {
    location: locations[0]
    avnmName: avnmName
    avnmDescription: avnmDescription
    tags: tags
  }
}

// Deploy per region resources (AVNM Network Groups, Policy Definitions, Policy Assignments, VNets)

@batchSize(1)
module perRegion './modules/perRegion.bicep' = [
  for loc in locations: {
    name: 'perRegion-${loc}'
    scope: rg
    params: {
      location: loc
      avnmName: avnmName
      vnetCount: vnetCount
    }
  }
]

// Deploy AVNM Network Group for Hub VNets

module avnmNgHubs 'modules/avnmNgHubs.bicep' = {
  name: 'Hubs-NG'
  scope: rg
  params: {
    avnmName: avnmName
    avnmNgName: 'NG-Hubs'
    hubVnets: [
      for i in range(0, length(locations)): {
        id: perRegion[i].outputs.hubVnet.id
        name: perRegion[i].outputs.hubVnet.name
      }
    ]
  }
}
