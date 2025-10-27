param existingAksName string

@description('Enable RBAC using AAD')
param enableAzureRBAC bool = false

@description('If automated deployment, for the 3 automated user assignments, set Principal Type on each to "ServicePrincipal" rarter than "User"')
param automatedDeployment bool = false

@description('The principal ID to assign the AKS admin role.')
param adminPrincipalId string = ''
// for AAD Integrated Cluster wusing 'enableAzureRBAC', add Cluster admin to the current user!
var buildInAKSRBACClusterAdmin = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
)

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: existingAksName
}

resource aks_admin_role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAzureRBAC && !empty(adminPrincipalId)) {
  scope: aks
  name: guid(aks.id, 'aksadmin', buildInAKSRBACClusterAdmin)
  properties: {
    roleDefinitionId: buildInAKSRBACClusterAdmin
    principalId: adminPrincipalId
    principalType: automatedDeployment ? 'ServicePrincipal' : 'User'
  }
}
