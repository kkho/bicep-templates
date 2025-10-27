param name string = ''
param eventGridName string = ''
param workspaceId string = ''
param createLaw bool = false
param createEventGrid bool = false

resource eventGrid 'Microsoft.EventGrid/systemTopics@2023-06-01-preview' existing = if (createEventGrid) {
  name: eventGridName
}

output eventGridName string = createEventGrid ? eventGrid.name : ''

resource eventGridDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (createLaw && createEventGrid) {
  name: name
  scope: eventGrid
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'DeliveryFailures'
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
