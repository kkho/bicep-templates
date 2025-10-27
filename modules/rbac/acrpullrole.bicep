param acrName string
param aksName string
param registries_sku string = ''

var AcrPullRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: acrName
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

var KubeletObjectId = any(aks.properties.identityProfile.kubeletidentity).objectId

resource aks_acr_pull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registries_sku)) {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'Acr', AcrPullRole)
  properties: {
    roleDefinitionId: AcrPullRole
    principalType: 'ServicePrincipal'
    principalId: KubeletObjectId
  }
}
