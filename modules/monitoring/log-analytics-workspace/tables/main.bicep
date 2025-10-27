param aksName string
param tableName string
param logAnalyticsWorkspaceName string
param enableBasicLogs bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: aksName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerLogsV2_Basiclogs 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if (enableBasicLogs) {
  name: tableName
  parent: logAnalyticsWorkspace
  properties: {
    plan: 'Basic'
  }
  dependsOn: [
    aks
  ]
}
