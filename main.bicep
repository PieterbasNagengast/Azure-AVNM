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

@description('Array of objects representing regions and their CIDR blocks.')
param regions _regions = [
  {
    location: 'swedencentral'
    cidr: '172.16.0.0/16'
  }
  {
    location: 'germanywestcentral'
    cidr: '172.32.0.0/16'
  }
]

type _regions = {
  location: string
  cidr: string
}[]

// Deploy resource group
resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgName
  location: regions[0].location
  tags: tags
}

// Deploy Azure Virtual Network Manager and Network Group
module avnm './modules/avnm.bicep' = {
  name: 'avnmDeployment'
  scope: rg
  params: {
    location: regions[0].location
    avnmName: avnmName
    avnmDescription: avnmDescription
    tags: tags
  }
}

// Deploy per region resources (AVNM Network Groups, Policy Definitions, Policy Assignments, VNets)
module perRegion './modules/perRegion.bicep' = [
  for (region, i) in regions: {
    name: 'perRegion-${region.location}'
    scope: rg
    params: {
      location: region.location
      avnmName: avnmName
      vnetCount: vnetCount
      cidr: region.cidr
    }
  }
]

// Deploy AVNM Network Group for Hub VNets
module avnmNgHubs 'modules/avnmNg.bicep' = {
  name: 'Hubs-NG'
  scope: rg
  params: {
    avnmName: avnmName
    avnmNgName: 'NG-Hubs'
    avnmNgDescription: 'Network Group for Hub VNets'
    Vnets: [for i in range(0, length(regions)): perRegion[i].outputs.hubVnet]
  }
}

// Deploy AVNM Connectivity Configuration for Hub VNets
module avnmConnectivity 'modules/avnmConnectivity.bicep' = {
  name: 'Connectivity-Hubs'
  scope: rg
  params: {
    avnmName: avnmName
    connectivityConfigName: 'Connectivity-Hubs'
    networkGroupId: avnmNgHubs.outputs.avnmNgId
    groupConnectivity: 'None'
    connectivitytopology: 'Mesh'
    deleteExistingPeering: 'False'
  }
}
