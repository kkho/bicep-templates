param enableTelemetry bool = false
param telemetryId string = 'telemetryDeployment'

#disable-next-line no-deployments-resources
resource telemetry 'Microsoft.Resources/deployments@2025-04-01' = if (enableTelemetry) {
  name: telemetryId
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}
