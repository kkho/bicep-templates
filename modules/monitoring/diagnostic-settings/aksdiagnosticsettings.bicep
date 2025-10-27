param diagnosticName string

param existingAksName string

param workSpaceId string

param createLaw bool

param isAnotherResourceCreated bool

@description('Diagnostic categories to log')
param diagnosticCategories array = []

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: existingAksName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (createLaw && isAnotherResourceCreated) {
  name: diagnosticName
  scope: aks
  properties: {
    workspaceId: workSpaceId
    logs: [
      for diagnosticCategory in diagnosticCategories: {
        category: diagnosticCategory
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
