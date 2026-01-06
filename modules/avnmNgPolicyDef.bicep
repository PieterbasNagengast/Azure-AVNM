targetScope = 'subscription'

param networkGroupId string

// Policy Definition to add vnets with tag 'avnmManaged:true' to the specified network group
resource policyDef 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'Add-AVNM-Managed-VNets-To-Network-Group'
  properties: {
    displayName: 'Add AVNM Managed VNets to Network Group'
    description: 'Automatically adds virtual networks tagged with avnmManaged:true to the specified AVNM network group.'
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
