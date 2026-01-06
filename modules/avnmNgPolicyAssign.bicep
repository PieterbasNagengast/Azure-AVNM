param policyAssignName string
param policyLocation string
param policyDefId string
param avnmNgName string

resource policyAssign 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: policyAssignName
  properties: {
    displayName: 'Add VNets to AVNMNetwork Group for ${avnmNgName} in ${policyLocation}'
    description: 'Policy Assignment to automatically add virtual networks tagged with avnmManaged:true in ${policyLocation} to the AVNM network group: ${avnmNgName}'
    policyDefinitionId: policyDefId
    resourceSelectors: [
      {
        name: 'LocationSelector'
        selectors: [
          {
            kind: 'resourceLocation'
            in: [
              policyLocation
            ]
          }
        ]
      }
    ]
  }
}
