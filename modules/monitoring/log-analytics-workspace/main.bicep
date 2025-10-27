param lawName string

param createLaw bool = false

param location string = resourceGroup().location

@description('The Log Analytics retention period')
param retentionInDays int = 30

@description('The Log Analytics daily data cap (GB) (0=no limit)')
param logDataCap int = 0

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (createLaw) {
  name: take('${lawName}-aks-law', 56)
  location: location
  properties: union(
    {
      retentionInDays: retentionInDays
      sku: {
        name: 'PerGB2018'
      }
    },
    logDataCap > 0
      ? {
          workspaceCapping: {
            dailyQuotaGb: logDataCap
          }
        }
      : {}
  )
}

output id string = createLaw ? logAnalyticsWorkspace.id : ''
