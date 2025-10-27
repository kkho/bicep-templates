param resourceName string
param location string = resourceGroup().location

param networkPluginIsKubenet bool = false
param aksPrincipleId string = ''

param vnetAddressPrefix string
param vnetAksSubnetAddressPrefix string

param cniDynamicIpAllocation bool = false

@description('Provide the vnetPodAddressPrefix when using cniDynamicIpAllocation')
param vnetPodAddressPrefix string = ''

//Nsg
param workspaceName string = ''
param workspaceResourceGroupName string = ''
param networkSecurityGroups bool = true

//Firewall
param azureFirewalls bool = false
param azureFirewallSku string = 'Basic'
param azureFirewallsManagementSeperation bool = azureFirewalls && azureFirewallSku == 'Basic'
param vnetFirewallSubnetAddressPrefix string = ''
param vnetFirewallManagementSubnetAddressPrefix string = ''

//Ingress
param ingressApplicationGateway bool = false
param ingressApplicationGatewayPublic bool = false
param vnetAppGatewaySubnetAddressPrefix string = ''

//Private Link
param privateLinks bool = false
param privateLinkSubnetAddressPrefix string = ''
param privateLinkAcrId string = ''
param privateLinkAkvId string = ''

//ACR
param acrPrivatePool bool = false
param acrAgentPoolSubnetAddressPrefix string = ''

//NatGatewayEgress
param natGateway bool = false
param natGatewayPublicIps int = 2
param natGatewayIdleTimeoutMins int = 30

//Bastion
param bastion bool = false
param bastionSubnetAddressPrefix string = ''

@description('Used by the Bastion Public IP')
param availabilityZones array = []

var bastion_subnet_name = 'AzureBastionSubnet'
var bastion_baseSubnet = {
  name: bastion_subnet_name
  properties: {
    addressPrefix: bastionSubnetAddressPrefix
  }
}
var bastion_subnet = bastion && networkSecurityGroups
  ? union(bastion_baseSubnet, nsgBastion.outputs.nsgSubnetObj)
  : bastion_baseSubnet

//NatGatewayEgress

var NatAvailabilityZone = array(first(availabilityZones))

var acrpool_subnet_name = 'acrpool-sn'
var acrpool_baseSubnet = {
  name: acrpool_subnet_name
  properties: {
    addressPrefix: acrAgentPoolSubnetAddressPrefix
  }
}
var acrpool_subnet = privateLinks && networkSecurityGroups
  ? union(acrpool_baseSubnet, nsgAcrPool.outputs.nsgSubnetObj)
  : acrpool_baseSubnet

var private_link_subnet_name = 'privatelinks-sn'
var private_link_baseSubnet = {
  name: private_link_subnet_name
  properties: {
    addressPrefix: privateLinkSubnetAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}
var private_link_subnet = privateLinks && networkSecurityGroups
  ? union(private_link_baseSubnet, nsgPrivateLinks.outputs.nsgSubnetObj)
  : private_link_baseSubnet

var appgw_subnet_name = 'appgw-sn'
var appgw_baseSubnet = {
  name: appgw_subnet_name
  properties: {
    addressPrefix: vnetAppGatewaySubnetAddressPrefix
  }
}
var appgw_subnet = ingressApplicationGateway && networkSecurityGroups
  ? union(appgw_baseSubnet, nsgAppGw.outputs.nsgSubnetObj)
  : appgw_baseSubnet

var fw_subnet_name = 'AzureFirewallSubnet' // Required by FW
var fw_subnet = {
  name: fw_subnet_name
  properties: {
    addressPrefix: vnetFirewallSubnetAddressPrefix
  }
}

/// ---- Firewall VNET config
module calcAzFwIp '../../modules/networking/firewall/calcAzFwip.bicep' = if (azureFirewalls) {
  name: take('${deployment().name}-calcAzFwIp', 64)
  params: {
    vnetFirewallSubnetAddressPrefix: vnetFirewallSubnetAddressPrefix
  }
}

var fwmgmt_subnet_name = 'AzureFirewallManagementSubnet' // Required by FW
var fwmgmt_subnet = {
  name: fwmgmt_subnet_name
  properties: {
    addressPrefix: vnetFirewallManagementSubnetAddressPrefix
  }
}

var routeFwTableName = '${resourceName}-rt-afw'
resource vnet_udr 'Microsoft.Network/routeTables@2024-10-01' = if (azureFirewalls) {
  name: routeFwTableName
  location: location
  properties: {
    routes: [
      {
        name: 'AKSNodeEgress'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewalls ? calcAzFwIp.outputs.firewallPrivateIp : null
        }
      }
    ]
  }
}

var contributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)

@description('Required for kubenet networking')
resource vnet_udr_rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (azureFirewalls && !empty(aksPrincipleId) && networkPluginIsKubenet) {
  name: guid(vnet_udr.id, contributorRoleId, aksPrincipleId)
  scope: vnet_udr
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: aksPrincipleId
    principalType: 'ServicePrincipal'
  }
}

var aks_subnet_name = 'aks-sn'
var aks_baseSubnet = {
  name: aks_subnet_name
  properties: union(
    {
      addressPrefix: vnetAksSubnetAddressPrefix
    },
    privateLinks
      ? {
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      : {},
    natGateway
      ? {
          natGateway: {
            id: natGw.id
          }
        }
      : {},
    azureFirewalls
      ? {
          routeTable: {
            id: vnet_udr.id
          }
        }
      : {}
  )
}

var aks_podSubnet_name = 'aks-pods-sn'
var aks_podSubnet = {
  name: aks_podSubnet_name
  properties: union(
    {
      addressPrefix: vnetPodAddressPrefix
    },
    privateLinks
      ? {
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      : {},
    natGateway
      ? {
          natGateway: {
            id: natGw.id
          }
        }
      : {},
    azureFirewalls
      ? {
          routeTable: {
            id: vnet_udr.id //resourceId('Microsoft.Network/routeTables', routeFwTableName)
          }
        }
      : {}
  )
}

var aks_subnet = networkSecurityGroups ? union(aks_baseSubnet, nsgAks.outputs.nsgSubnetObj) : aks_baseSubnet
var aks_finalPodSubnet = networkSecurityGroups ? union(aks_podSubnet, nsgAks.outputs.nsgSubnetObj) : aks_podSubnet

var subnets = union(
  array(aks_subnet),
  cniDynamicIpAllocation ? array(aks_finalPodSubnet) : [],
  azureFirewalls ? array(fw_subnet) : [],
  privateLinks ? array(private_link_subnet) : [],
  acrPrivatePool ? array(acrpool_subnet) : [],
  bastion ? array(bastion_subnet) : [],
  ingressApplicationGateway ? array(appgw_subnet) : [],
  azureFirewallsManagementSeperation ? array(fwmgmt_subnet) : []
)
output debugSubnets array = subnets

var vnetName = '${resourceName}-vnet'
resource vnet 'Microsoft.Network/virtualNetworks@2024-10-01' = {
  name: vnetName
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
output aksSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, aks_subnet_name)
output aksPodSubnetId string = cniDynamicIpAllocation
  ? resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, aks_podSubnet_name)
  : ''
output fwSubnetId string = azureFirewalls ? '${vnet.id}/subnets/${fw_subnet_name}' : ''
output fwMgmtSubnetId string = azureFirewallsManagementSeperation ? '${vnet.id}/subnets/${fwmgmt_subnet_name}' : ''
output acrPoolSubnetId string = acrPrivatePool ? '${vnet.id}/subnets/${acrpool_subnet_name}' : ''
output appGwSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, appgw_subnet_name)
output privateLinkSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  private_link_subnet_name
)

module aks_vnet_con '../../modules/networking/subnet/networksubnetrbac.bicep' = if (!empty(aksPrincipleId)) {
  name: take('${deployment().name}-aks-vnet-con', 64)
  params: {
    servicePrincipalId: aksPrincipleId
    subnetName: aks_subnet_name
    vnetName: vnet.name
  }
}

// Private link for ACR
var privateLinkAcrName = '${resourceName}-pl-acr'
resource privateLinkAcr 'Microsoft.Network/privateEndpoints@2023-04-01' = if (!empty(privateLinkAcrId)) {
  name: privateLinkAcrName
  location: location
  properties: {
    customNetworkInterfaceName: '${privateLinkAcrName}-nic'
    privateLinkServiceConnections: [
      {
        name: 'Acr-Connection'
        properties: {
          privateLinkServiceId: privateLinkAcrId
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/${private_link_subnet_name}'
    }
  }
}

resource privateDnsAcr 'Microsoft.Network/privateDnsZones@2024-06-01' = if (!empty(privateLinkAcrId)) {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

var privateDnsAcrLinkName = 'vnet-dns'
resource privateDnsAcrLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateLinkAcrId)) {
  name: privateDnsAcrLinkName
  parent: privateDnsAcr
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource privateDnsAcrZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = if (!empty(privateLinkAcrId)) {
  parent: privateLinkAcr
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vnet-pl-acr'
        properties: {
          privateDnsZoneId: privateDnsAcr.id
        }
      }
    ]
  }
}

var privateLinkAkvName = '${resourceName}-pl-akv'
resource privateLinkAkv 'Microsoft.Network/privateEndpoints@2024-10-01' = if (!empty(privateLinkAkvId)) {
  name: privateLinkAkvName
  location: location
  properties: {
    customNetworkInterfaceName: '${privateLinkAkvName}-nic'
    privateLinkServiceConnections: [
      {
        name: 'Akv-Connection'
        properties: {
          privateLinkServiceId: privateLinkAkvId
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: '${vnet.id}/subnets/${private_link_subnet_name}'
    }
  }
}

resource privateDnsAkv 'Microsoft.Network/privateDnsZones@2024-06-01' = if (!empty(privateLinkAkvId)) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

var privateDnsAkvLinkName = '${resourceName}-vnet-dnscr'
resource privateDnsAkvLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (!empty(privateLinkAkvId)) {
  parent: privateDnsAkv
  name: privateDnsAkvLinkName
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateDnsAkvZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = if (!empty(privateLinkAkvId)) {
  parent: privateLinkAkv
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vnet-pl-akv'
        properties: {
          privateDnsZoneId: privateDnsAkv.id
        }
      }
    ]
  }
}

param bastionHostName string = '${resourceName}-bas'
var publicIpAddressName = '${bastionHostName}-pip'

@allowed([
  'Standard'
  'Basic'
])
param bastionSku string = 'Standard'

resource bastionPip 'Microsoft.Network/publicIPAddresses@2024-10-01' = if (bastion) {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: !empty(availabilityZones) ? availabilityZones : []
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2024-10-01' = if (bastion) {
  name: bastionHostName
  location: location
  sku: {
    name: bastionSku
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${bastion_subnet_name}'
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

resource log 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = if (networkSecurityGroups && !empty(workspaceName)) {
  name: workspaceName
  scope: resourceGroup(workspaceResourceGroupName)
}

param createNsgFlowLogs bool = false

var flowLogStorageNameBase = take(
  replace(toLower('stflow${resourceName}${uniqueString(resourceGroup().id, resourceName)}'), '-', ''),
  24
)
var flowLogStorageName = length(flowLogStorageNameBase) < 3
  ? 'stf${uniqueString(resourceGroup().id)}'
  : flowLogStorageNameBase

resource flowLogStorage 'Microsoft.Storage/storageAccounts@2025-01-01' = if (createNsgFlowLogs && networkSecurityGroups) {
  name: flowLogStorageName
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  location: location
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

// NSG
module nsgAks '../../modules/networking/nsg/main.bicep' = if (networkSecurityGroups) {
  name: take('${deployment().name}-nsg-aks', 64)
  params: {
    location: location
    resourceName: '${resourceName}-${aks_subnet_name}'
    workspaceId: !empty(workspaceName) ? log.properties.customerId : ''
    workspaceRegion: !empty(workspaceName) ? log.location : ''
    workspaceResourceId: !empty(workspaceName) ? log.id : ''
    ruleInAllowInternetHttp: true
    ruleInAllowInternetHttps: true
    ruleInDenySsh: true
    FlowLogStorageAccountId: createNsgFlowLogs ? flowLogStorage.id : ''
  }
}

module nsgAcrPool '../../modules/networking/nsg/main.bicep' = if (acrPrivatePool && networkSecurityGroups) {
  name: take('${deployment().name}-nsg-acrpool', 64)
  params: {
    location: location
    resourceName: '${resourceName}-${acrpool_subnet_name}'
    workspaceId: !empty(workspaceName) ? log.properties.customerId : ''
    workspaceRegion: !empty(workspaceName) ? log.location : ''
    workspaceResourceId: !empty(workspaceName) ? log.id : ''
    FlowLogStorageAccountId: createNsgFlowLogs ? flowLogStorage.id : ''
  }
  dependsOn: [
    nsgAks
  ]
}

module nsgAppGw '../../modules/networking/nsg/main.bicep' = if (ingressApplicationGateway && networkSecurityGroups) {
  name: take('${deployment().name}-nsg-appgw', 64)
  params: {
    location: location
    resourceName: '${resourceName}-${appgw_subnet_name}'
    workspaceId: !empty(workspaceName) ? log.properties.customerId : ''
    workspaceRegion: !empty(workspaceName) ? log.location : ''
    workspaceResourceId: !empty(workspaceName) ? log.id : ''
    ruleInAllowInternetHttp: ingressApplicationGatewayPublic
    ruleInAllowInternetHttps: ingressApplicationGatewayPublic
    ruleInAllowGwManagement: true
    ruleInAllowAzureLoadBalancer: true
    ruleInDenyInternet: true
    ruleInGwManagementPort: '65200-65535'
    FlowLogStorageAccountId: createNsgFlowLogs ? flowLogStorage.id : ''
  }
  dependsOn: [
    nsgAcrPool
  ]
}

module nsgBastion '../../modules/networking/nsg/main.bicep' = if (bastion && networkSecurityGroups) {
  name: take('${deployment().name}-nsg-bastion', 64)
  params: {
    location: location
    resourceName: '${resourceName}-${bastion_subnet_name}'
    workspaceId: !empty(workspaceName) ? log.properties.customerId : ''
    workspaceRegion: !empty(workspaceName) ? log.location : ''
    workspaceResourceId: !empty(workspaceName) ? log.id : ''
    ruleInAllowBastionHostComms: true
    ruleInAllowInternetHttps: true
    ruleInAllowGwManagement: true
    ruleInAllowAzureLoadBalancer: true
    ruleOutAllowBastionComms: true
    ruleInGwManagementPort: '443'
    FlowLogStorageAccountId: createNsgFlowLogs ? flowLogStorage.id : ''
  }
  dependsOn: [
    nsgAppGw
  ]
}

module nsgPrivateLinks '../../modules/networking/nsg/main.bicep' = if (privateLinks && networkSecurityGroups) {
  name: take('${deployment().name}-nsg-privatelinks', 64)
  params: {
    location: location
    resourceName: '${resourceName}-${private_link_subnet_name}'
    workspaceId: !empty(workspaceName) ? log.properties.customerId : ''
    workspaceRegion: !empty(workspaceName) ? log.location : ''
    workspaceResourceId: !empty(workspaceName) ? log.id : ''
    FlowLogStorageAccountId: createNsgFlowLogs ? flowLogStorage.id : ''
  }
  dependsOn: [
    nsgBastion
  ]
}

resource natGwIp 'Microsoft.Network/publicIPAddresses@2024-10-01' = [
  for i in range(0, natGatewayPublicIps): if (natGateway) {
    name: 'pip-${natGwName}-${i+1}'
    location: location
    sku: {
      name: 'Standard'
    }
    zones: !empty(availabilityZones) ? NatAvailabilityZone : []
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]

output natGwIpArr array = [for i in range(0, natGatewayPublicIps): natGateway ? natGwIp[i].properties.ipAddress : null]
var natGwName = '${resourceName}-ng'

resource natGw 'Microsoft.Network/natGateways@2024-10-01' = if (natGateway) {
  name: natGwName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: !empty(availabilityZones) ? NatAvailabilityZone : []
  properties: {
    publicIpAddresses: [
      for i in range(0, natGatewayPublicIps): {
        id: natGwIp[i].id
      }
    ]
    idleTimeoutInMinutes: natGatewayIdleTimeoutMins
  }
  dependsOn: [
    natGwIp
  ]
}
