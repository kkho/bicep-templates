param aksName string = ''
param appGatewayName string = ''
param ingressApplicationGateway bool = false
param deployAppGw bool = false

var contributor = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

resource appgw 'Microsoft.Network/applicationGateways@2023-11-01' existing = {
  name: appGatewayName
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template#new-service-principal
// AGIC's identity requires "Contributor" permission over Application Gateway.
resource appGwAGICContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (ingressApplicationGateway && deployAppGw) {
  scope: appgw
  name: guid(aks.id, 'Agic', contributor)
  properties: {
    roleDefinitionId: contributor
    principalType: 'ServicePrincipal'
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
  }
}
