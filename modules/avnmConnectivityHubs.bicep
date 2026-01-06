resource avnmConnectivityHubs 'Microsoft.Network/virtualNetworkManagers/connectivityConfigurations/hubResources@2023-11-01' = {
  name: '${connectivityConfigName}/hubResources/${hubResourceName}'
  properties: {
    resourceId: hubResourceId
    networkGroupId: networkGroupId
  }
}
