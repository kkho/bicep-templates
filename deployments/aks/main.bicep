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

output aksClusterName string = aks.name
output aksOidcIssuerUrl string = oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''

@description('This output can be directly leveraged when creating a ManagedId Federated Identity')
output aksOidcFedIdentityProperties object = {
  issuer: oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
  audiences: ['api://AzureADTokenExchange']
  subject: 'system:serviceaccount:ns:svcaccount'
}

@description('The name of the managed resource group AKS uses')
output aksNodeResourceGroup string = aks.properties.nodeResourceGroup

@description('The Azure resource id for the AKS cluster')
output aksResourceId string = aks.id
