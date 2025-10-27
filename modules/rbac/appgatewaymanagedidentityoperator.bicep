param aksName string = ''
param appGatewayManagedIdentityName string = ''
param ingressApplicationGateway bool = false
param deployAppGw bool = false

var managedIdentityOperator = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'f1a07417-d97a-45cb-824c-7a7467783830'
)

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appGatewayManagedIdentityName
}

resource appGwAGICMIOp 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (ingressApplicationGateway && deployAppGw) {
  scope: appGwIdentity
  name: guid(aks.id, 'Agic', managedIdentityOperator)
  properties: {
    roleDefinitionId: managedIdentityOperator
    principalType: 'ServicePrincipal'
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
  }
}
