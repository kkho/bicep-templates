param resourceName string
param location string = resourceGroup().location
param aksProperties object
param createAksUai bool = false
param aksUai object
param byoUaiName string = ''
param byoAksUai object
param akssku string = 'Free'
param oidcIssuer bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: 'aks-${resourceName}'
  location: location
  properties: aksProperties
  identity: createAksUai
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${aksUai.id}': {}
        }
      }
    : !empty(byoUaiName)
        ? {
            type: 'UserAssigned'
            userAssignedIdentities: {
              '${byoAksUai.id}': {}
            }
          }
        : {
            type: 'SystemAssigned'
          }
  sku: {
    name: 'Base'
    tier: akssku
  }
}

output id string = aks.id
output identityProfile object = aks.properties.identityProfile
output aksClusterName string = aks.name
output aksOidcIssuerUrl string = oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
output properties object = aks.properties
