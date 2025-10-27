param aksName string = ''
param ingressApplicationGateway bool = false
param deployAppGw bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

var reader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
resource appGwAGICRGReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (ingressApplicationGateway && deployAppGw) {
  scope: resourceGroup()
  name: guid(aks.id, 'Agic', reader)
  properties: {
    roleDefinitionId: reader
    principalType: 'ServicePrincipal'
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
  }
}
