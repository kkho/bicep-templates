param resourceName string
param location string = resourceGroup().location
@allowed([
  ''
  'audit'
  'deny'
])
@description('Enable the Azure Policy addon')
param azurepolicy string = ''
@allowed([
  'Baseline'
  'Restricted'
])
param azurePolicyInitiative string = 'Baseline'
param policySetBaseline string = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
param policySetRestrictive string = '/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00'

resource aks_policies 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (!empty(azurepolicy)) {
  name: '${resourceName}-${azurePolicyInitiative}'
  location: location
  properties: {
    policyDefinitionId: azurePolicyInitiative == 'Baseline' ? policySetBaseline : policySetRestrictive
    parameters: {
      excludedNamespaces: {
        value: [
          'kube-system'
          'gatekeeper-system'
          'azure-arc'
          'cluster-baseline-setting'
        ]
      }
      effect: {
        value: azurepolicy
      }
    }
    metadata: {
      assignedBy: 'Aks Construction'
    }
    displayName: 'Kubernetes cluster pod security ${azurePolicyInitiative} standards for Linux-based workloads'
    description: 'As per: https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/'
  }
}
