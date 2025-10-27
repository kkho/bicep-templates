param acrName string = ''
param aksName string = ''
param registries_sku string = ''
param automatedDeployment bool = true
@description('The principal ID of the service principal to assign the push role to the ACR')
param acrPushRolePrincipalId string = ''

var AcrPushRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '8311e382-0749-4cb8-b61a-304f252e45ec'
)

resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: acrName
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

resource aks_acr_push 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registries_sku) && !empty(acrPushRolePrincipalId)) {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'Acr', AcrPushRole)
  properties: {
    roleDefinitionId: AcrPushRole
    principalType: automatedDeployment ? 'ServicePrincipal' : 'User'
    principalId: acrPushRolePrincipalId
  }
}
