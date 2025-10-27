param resourceName string
param location string = resourceGroup().location
param vnetAddressPrefix string
param subnets array

var vNetName = '${resourceName}-vnet'
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: subnets
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
