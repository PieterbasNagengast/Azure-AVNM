targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'VNETs-should-have-IPAM-pool-allocation'
  properties: {
    displayName: 'VNETs should have IPAM pool allocation'
    description: 'Ensures that all Virtual Networks have IPAM pool prefix allocations defined for address space.'
    mode: 'indexed'
    metadata: {
      category: 'AVNM IPAM Management'
    }
    parameters: {
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
          description: 'The effect of the policy.'
        }
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
        defaultValue: 'Audit'
      }
    }
    policyType: 'Custom'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Network/virtualNetworks'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.Network/virtualNetworks/addressSpace.ipamPoolPrefixAllocations'
                exists: 'false'
              }
              {
                count: {
                  field: 'Microsoft.Network/virtualNetworks/addressSpace.ipamPoolPrefixAllocations[*]'
                }
                equals: 0
              }
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
