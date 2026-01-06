param policyAssignName string
param policyLocation array

param policyDefId string

resource policyAssign 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: policyAssignName
  properties: {
    displayName: 'Assign Policy to add AVNM Managed VNets to Network Group'
    description: 'Policy Assignment to automatically add virtual networks tagged with avnmManaged:true to the specified AVNM network group.'
    policyDefinitionId: policyDefId
    resourceSelectors: [
      {
        name: 'LocationSelector'
        selectors: [
          {
            kind: 'resourceLocation'
            in: policyLocation
          }
        ]
      }
    ]
  }
}
