@description('Name of the Azure Virtual Network Manager.')
param avnmName string

@description('Address prefixes for the IPAM Pool.')
param addressPrefixes string

@description('Location for the IPAM Pool.')
param location string

@description('Tags to be applied to all resources.')
param tags object = {}

// Get existing AVNM resource
resource avnm 'Microsoft.Network/networkManagers@2025-01-01' existing = {
  name: avnmName
}

// Create IPAM Pool
resource avnmIPAMroot 'Microsoft.Network/networkManagers/ipamPools@2025-01-01' = {
  name: 'IPAMPool-Root-${location}'
  parent: avnm
  location: location
  properties: {
    displayName: 'Root IPAM Pool [${location}]'
    description: 'Root IPAM Pool for region ${location}'
    addressPrefixes: [
      addressPrefixes
    ]
  }
  tags: tags
}

// Create Child IPAM Pools
resource avnmIPAMchild1 'Microsoft.Network/networkManagers/ipamPools@2025-01-01' = {
  name: 'IPAMPool-Child-1-${location}'
  parent: avnm
  location: location
  properties: {
    displayName: 'Child IPAM Pool 1 [${location}]'
    description: 'Child IPAM Pool 1 for region ${location}'
    parentPoolName: avnmIPAMroot.name
    addressPrefixes: [
      cidrSubnet(addressPrefixes, 17, 0)
    ]
  }
  tags: tags
}

// Create Child IPAM Pools
resource avnmIPAMchild2 'Microsoft.Network/networkManagers/ipamPools@2025-01-01' = {
  name: 'IPAMPool-Child-2-${location}'
  parent: avnm
  location: location
  properties: {
    displayName: 'Child IPAM Pool 2 [${location}]'
    description: 'Child IPAM Pool 2 for region ${location}'
    parentPoolName: avnmIPAMroot.name
    addressPrefixes: [
      cidrSubnet(addressPrefixes, 17, 1)
    ]
  }
  tags: tags
  dependsOn: [
    avnmIPAMchild1
  ]
}

output ipamPoolRootId string = avnmIPAMroot.id
output ipamPoolChild1Id string = avnmIPAMchild1.id
output ipamPoolChild2Id string = avnmIPAMchild2.id
