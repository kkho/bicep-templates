param existingAksName string
param createLaw bool = false
param aksLawName string
param omsagent bool = false

//This role assignment enables AKS->LA Fast Alerting experience
var MonitoringMetricsPublisherRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '3913510d-42f4-4e42-8a64-420c390055eb'
)

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: existingAksName
}

resource aks_law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (createLaw) {
  name: aksLawName
}

resource FastAlertingRole_Aks_Law 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (omsagent) {
  scope: aks
  name: guid(aks.id, 'omsagent', MonitoringMetricsPublisherRole)
  properties: {
    roleDefinitionId: MonitoringMetricsPublisherRole
    principalId: aks.properties.addonProfiles.omsagent.identity.objectId
    principalType: 'ServicePrincipal'
  }
}

output LogAnalyticsName string = (createLaw) ? aks_law.name : ''
output LogAnalyticsGuid string = (createLaw) ? aks_law.properties.customerId : ''
output LogAnalyticsId string = (createLaw) ? aks_law.id : ''
