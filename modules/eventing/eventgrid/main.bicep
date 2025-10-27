param name string
param location string = resourceGroup().location
param sourceId string = ''
@description('Create an Event Grid System Topic for AKS events')
param createEventGrid bool = false
param topicType string = 'Microsoft.ContainerService.ManagedClusters'

resource eventGrid 'Microsoft.EventGrid/systemTopics@2023-06-01-preview' = if (createEventGrid) {
  name: '${name}-eventgridtopic'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    source: sourceId
    topicType: topicType
  }
}

output eventGridId string = createEventGrid ? eventGrid.id : ''
output eventGridName string = createEventGrid ? eventGrid.name : ''
