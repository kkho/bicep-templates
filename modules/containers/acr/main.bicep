@allowed([
  ''
  'Basic'
  'Standard'
  'Premium'
])
@description('The SKU of the Azure Container Registry. Allowed values: Basic, Standard, Premium. Leave empty to skip ACR creation.')
param registries_sku string

@description('The zones to use for a node pool')
param availabilityZones array = []

@description('Enable the ACR Content Trust Policy, SKU must be set to Premium')
param enableACRTrustPolicy bool = false

var acrContentTrustEnabled = enableACRTrustPolicy && registries_sku == 'Premium' ? 'enabled' : 'disabled'
var acrZoneRedundancyEnabled = !empty(availabilityZones) && registries_sku == 'Premium' ? 'Enabled' : 'Disabled'

@description('Enable support for private links (required custom_vnet)')
param privateLinks bool = false

@description('Enable removing of untagged manifests from ACR')
param acrUntaggedRetentionPolicyEnabled bool = false

@description('The number of days to retain untagged manifests for')
param acrUntaggedRetentionPolicy int = 30

param acrName string
param aksName string
param location string = resourceGroup().location
param aksResourceGroup string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (!empty(registries_sku)) {
  name: acrName
  location: location
  sku: {
    name: registries_sku
  }
  properties: {
    policies: {
      trustPolicy: enableACRTrustPolicy
        ? {
            status: acrContentTrustEnabled
            type: 'Notary'
          }
        : {}
      retentionPolicy: acrUntaggedRetentionPolicyEnabled
        ? {
            days: acrUntaggedRetentionPolicy
            status: 'enabled'
          }
        : null
    }
    publicNetworkAccess: privateLinks ? 'Disabled' : 'Enabled'
    zoneRedundancy: acrZoneRedundancyEnabled
  }
}

output containerRegistryName string = !empty(registries_sku) ? acr.name : ''
output containerRegistryId string = !empty(registries_sku) ? acr.id : ''
