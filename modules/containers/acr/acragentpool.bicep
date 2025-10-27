param location string = resourceGroup().location
param agentPoolName string = 'acr-agentpool'
param acrName string
param tier string = 'Basic'
param acrPoolSubnetId string = ''

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrAgentPool 'Microsoft.ContainerRegistry/registries/agentPools@2025-03-01-preview' = {
  name: agentPoolName
  location: location
  parent: acr
  properties: {
    count: 1
    os: 'Linux'
    tier: tier
    virtualNetworkSubnetResourceId: acrPoolSubnetId != '' ? acrPoolSubnetId : null
  }
}
