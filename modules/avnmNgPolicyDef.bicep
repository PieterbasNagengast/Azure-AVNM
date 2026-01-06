targetScope = 'subscription'

param networkGroupId string

// Policy Definition to add vnets with tag 'avnmManaged:true' to the specified network group
resource policyDef 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'Add-VNets-To-AVNM-Network-Group-${last(split(networkGroupId, '/'))}'
  properties: {
    displayName: 'Add VNets to AVNM Network Group ${last(split(networkGroupId, '/'))}'
    description: 'Automatically adds virtual networks tagged with avnmManaged:true to the ${last(split(networkGroupId, '/'))} AVNM network group'
    mode: 'Microsoft.Network.Data'
    metadata: {
      category: 'AVNM Network Group Management'
    }
    policyType: 'Custom'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'tags.avnmManaged'
            equals: 'true'
          }
        ]
      }
      then: {
        effect: 'addToNetworkGroup'
        details: {
          networkGroupId: networkGroupId
        }
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
