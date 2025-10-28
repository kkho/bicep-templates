@minLength(2)
@description('The location to use for the deployment. defualts to Resource Groups location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

/*
Resource sections
1. Networking
2. DNS
3. Key Vault
4. Container Registry
5. Firewall
6. Application Gateway
7. AKS
8. Monitoring / Log Analytics
9. Deployment for telemetry
*/

// 1. Networking (can be custom / byo / default)

@description('Own vNet CIDR blocks')
param custom_vnet bool = false

@description('full resource id path of an existing subnet to use for AKS')
param byoAKSSubnetId string = ''

@description('Full resource id path of an existing pod subnet to use for AKS')
param byoAKSPodSubnetId string = ''

@description('Full resource id path of an existing subnet to use for Application Gateway')
param byoAGWSubnetId string = ''

@description('The name of an existing UserAssigned Identity to use for the AKS Control Plane (in the same resource group),  requires rbac assignments to be done outside of this template')
param byoUaiName string = ''

// Custom, BYO networking and PrivateApiZones requires AKS User Identity
var createAksUai = (custom_vnet || !empty(byoAKSSubnetId) || !empty(dnsApiPrivateZoneId) || keyVaultKmsCreateAndPrereqs || !empty(keyVaultKmsByoKeyId)) && empty(byoUaiName)
resource aksUai 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = if (createAksUai) {
  name: '${resourceName}-id-aks'
  location: location
}

resource byoAksUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = if (!empty(byoUaiName)) {
  name: byoUaiName
}

var aksPrincipalId = !empty(byoUaiName)
  ? byoAksUai.properties.principalId
  : createAksUai ? aksUai.properties.principalId : ''

// BYO Vnet
var existingAksVnetRG = !empty(byoAKSSubnetId)
  ? (length(split(byoAKSSubnetId, '/')) > 4 ? split(byoAKSSubnetId, '/')[4] : '')
  : ''

module aksnetcontrib '../modules/compute/aks/asknetcontrib.bicep' = if (!empty(byoAKSSubnetId) && createAksUai) {
  name: take('${deployment().name}-addAksNetContributor', 64)
  scope: resourceGroup(existingAksVnetRG)
  params: {
    byoAKSSubnetId: byoAKSSubnetId
    byoAKSPodSubnetId: byoAKSPodSubnetId
    user_identity_principalId: createAksUai ? aksUai.properties.principalId : ''
    rbacAssignmentScope: uaiNetworkScopeRbac
  }
}

// Custom VNet Creation
@minLength(9)
@maxLength(18)
@description('The address range for the custom vnet')
param vnetAddressPrefix string = '10.240.0.0/16'

@minLength(9)
@maxLength(18)
@description('The address range for AKS in your custom vnet')
param vnetAksSubnetAddressPrefix string = '10.240.0.0/22'

@minLength(9)
@maxLength(18)
@description('The address range for the App Gateway in your custom vnet')
param vnetAppGatewaySubnetAddressPrefix string = '10.240.5.0/24'

@minLength(9)
@maxLength(18)
@description('The address range for the ACR in your custom vnet')
param acrAgentPoolSubnetAddressPrefix string = '10.240.4.64/26'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Bastion in your custom vnet')
param bastionSubnetAddressPrefix string = '10.240.4.128/26'

@minLength(9)
@maxLength(18)
@description('The address range for private link in your custom vnet')
param privateLinkSubnetAddressPrefix string = '10.240.4.192/26'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Firewall in your custom vnet')
param vnetFirewallSubnetAddressPrefix string = '10.240.50.0/24'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Firewall Management in your custom vnet')
param vnetFirewallManagementSubnetAddressPrefix string = '10.240.51.0/26'

@description('Enable support for private links (required custom_vnet)')
param privateLinks bool = false

@description('Enable support for ACR private pool')
param acrPrivatePool bool = false

@description('Deploy Azure Bastion to your vnet. (works with Custom Networking only, not BYO)')
param bastion bool = false

@description('Deploy NSGs to your vnet subnets. (works with Custom Networking only, not BYO)')
param CreateNetworkSecurityGroups bool = false

@description('Configure Flow Logs for Network Security Groups in the NetworkWatcherRG resource group. Requires Contributor RBAC on NetworkWatcherRG and Reader on Subscription.')
param CreateNetworkSecurityGroupFlowLogs bool = false

module network './network/main.bicep' = if (custom_vnet) {
  name: take('${deployment().name}-network', 64)
  params: {
    resourceName: resourceName
    location: location
    networkPluginIsKubenet: networkPlugin == 'kubenet'
    vnetAddressPrefix: vnetAddressPrefix
    vnetPodAddressPrefix: cniDynamicIpAllocation ? podCidr : ''
    cniDynamicIpAllocation: cniDynamicIpAllocation
    aksPrincipleId: aksPrincipalId
    vnetAksSubnetAddressPrefix: vnetAksSubnetAddressPrefix
    ingressApplicationGateway: ingressApplicationGateway
    vnetAppGatewaySubnetAddressPrefix: vnetAppGatewaySubnetAddressPrefix
    azureFirewalls: azureFirewalls
    azureFirewallSku: azureFirewallSku
    vnetFirewallSubnetAddressPrefix: vnetFirewallSubnetAddressPrefix
    vnetFirewallManagementSubnetAddressPrefix: vnetFirewallManagementSubnetAddressPrefix
    privateLinks: privateLinks
    privateLinkSubnetAddressPrefix: privateLinkSubnetAddressPrefix
    privateLinkAcrId: privateLinks && !empty(registries_sku) ? acr.id : ''
    privateLinkAkvId: privateLinks && keyVaultCreate ? kv.outputs.keyVaultId : ''
    acrPrivatePool: acrPrivatePool
    acrAgentPoolSubnetAddressPrefix: acrAgentPoolSubnetAddressPrefix
    bastion: bastion
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
    availabilityZones: availabilityZones
    workspaceName: createLaw ? aks_law.name : ''
    workspaceResourceGroupName: createLaw ? resourceGroup().name : ''
    networkSecurityGroups: CreateNetworkSecurityGroups
    createNsgFlowLogs: CreateNetworkSecurityGroups && CreateNetworkSecurityGroupFlowLogs
    ingressApplicationGatewayPublic: empty(privateIpApplicationGateway)
    natGateway: createNatGateway
    natGatewayIdleTimeoutMins: natGwIdleTimeout
    natGatewayPublicIps: natGwIpCount
  }
}
output CustomVnetId string = custom_vnet ? network.outputs.vnetId : ''
output CustomVnetPrivateLinkSubnetId string = custom_vnet ? network.outputs.privateLinkSubnetId : ''

var aksSubnetId = custom_vnet ? network.outputs.aksSubnetId : byoAKSSubnetId
var aksPodSubnetId = custom_vnet ? network.outputs.aksPodSubnetId : byoAKSPodSubnetId
var appGwSubnetId = ingressApplicationGateway ? (custom_vnet ? network.outputs.appGwSubnetId : byoAGWSubnetId) : ''

// 2. DNS Zones
@description('The full Azure resource ID of the DNS zone to use for the AKS cluster')
param dnsZoneId string = ''
var isDnsZonePrivate = !empty(dnsZoneId) ? split(dnsZoneId, '/')[7] == 'privateDnsZones' : false

module dnsZone '../modules/networking/dns-zone/main.bicep' = if (!empty(dnsZoneId) && isDnsZonePrivate) {
  name: take('${deployment().name}-dnszone', 64)
  params: {
    dnsZoneId: dnsZoneId
    vnetId: isDnsZonePrivate
      ? (!empty(byoAKSSubnetId) ? split(byoAKSSubnetId, '/subnets')[0] : (custom_vnet ? network.outputs.vnetId : ''))
      : ''
    principalId: any(aks.outputs.properties.identityProfile.kubeletidentity).objectId
  }
}

// 3. Key Vault
@description('Creates a KeyVault')
param keyVaultCreate bool = false

@description('If soft delete protection is enabled')
param keyVaultSoftDelete bool = true

@description('If purge protection is enabled')
param keyVaultPurgeProtection bool = true

@description('Add IP to KV firewall allow-list')
param keyVaultIPAllowlist array = []

@description('Installs the AKS KV CSI provider')
param keyVaultAksCSI bool = false

@description('Rotation poll interval for the AKS KV CSI provider')
param keyVaultAksCSIPollInterval string = '2m'

@description('Creates a KeyVault for application secrets (eg. CSI)')
module kv '../modules/security/keyvault/main.bicep' = if (keyVaultCreate) {
  name: take('${deployment().name}-keyvaultApps', 64)
  params: {
    resourceName: resourceName
    keyVaultPurgeProtection: keyVaultPurgeProtection
    keyVaultSoftDelete: keyVaultSoftDelete
    keyVaultIPAllowlist: keyVaultIPAllowlist
    location: location
    privateLinks: privateLinks
  }
}

@description('The principal ID of the user or service principal that requires access to the Key Vault. Set automatedDeployment to toggle between user and service prinicpal')
param keyVaultOfficerRolePrincipalId string = ''
var keyVaultOfficerRolePrincipalIds = [
  keyVaultOfficerRolePrincipalId
]
@description('Parsing an array with union ensures that duplicates are removed, which is great when dealing with highly conditional elements')
var rbacSecretUserSps = union(
  [deployAppGw && appgwKVIntegration ? appGwIdentity.properties.principalId : ''],
  [keyVaultAksCSI ? aks.outputs.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId : '']
)

@description('A seperate module is used for RBAC to avoid delaying the KeyVault creation and causing a circular reference.')
module kvRbac '../modules/security/keyvault/keyvault-rbac.bicep' = if (keyVaultCreate) {
  name: take('${deployment().name}-keyvaultRbac', 64)
  dependsOn: [
    kv
  ]
  params: {
    keyVaultName: kv.outputs.keyVaultName
    rbacSecretUserSps: rbacSecretUserSps
    rbacSecretOfficerSps: !empty(keyVaultOfficerRolePrincipalId) && automatedDeployment
      ? keyVaultOfficerRolePrincipalIds
      : []
    rbacCertOfficerSps: !empty(keyVaultOfficerRolePrincipalId) && automatedDeployment
      ? keyVaultOfficerRolePrincipalIds
      : []
    //users
    rbacSecretOfficerUsers: !empty(keyVaultOfficerRolePrincipalId) && !automatedDeployment
      ? keyVaultOfficerRolePrincipalIds
      : []
    rbacCertOfficerUsers: !empty(keyVaultOfficerRolePrincipalId) && !automatedDeployment
      ? keyVaultOfficerRolePrincipalIds
      : []
  }
}

output keyVaultName string = keyVaultCreate ? kv.outputs.keyVaultName : ''
output keyVaultId string = keyVaultCreate ? kv.outputs.keyVaultId : ''

/* KeyVault for KMS Etcd*/

@description('Enable encryption at rest for Kubernetes etcd data')
param keyVaultKmsCreate bool = false

@description('Bring an existing Key from an existing Key Vault')
param keyVaultKmsByoKeyId string = ''

@description('The resource group for the existing KMS Key Vault')
param keyVaultKmsByoRG string = resourceGroup().name

@description('The PrincipalId of the deploying user, which is necessary when creating a Kms Key')
param keyVaultKmsOfficerRolePrincipalId string = ''

@description('The extracted name of the existing Key Vault')
var keyVaultKmsByoName = !empty(keyVaultKmsByoKeyId) ? split(split(keyVaultKmsByoKeyId, '/')[2], '.')[0] : ''

@description('The deployment delay to introduce when creating a new keyvault for kms key')
var kmsRbacWaitSeconds = 30

@description('This indicates if the deploying user has provided their PrincipalId in order for the key to be created')
var keyVaultKmsCreateAndPrereqs = keyVaultKmsCreate && !empty(keyVaultKmsOfficerRolePrincipalId) && privateLinks == false

resource kvKmsByo 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultKmsByoName)) {
  name: keyVaultKmsByoName
  scope: resourceGroup(keyVaultKmsByoRG)
}

@description('Creates a new Key vault for a new KMS Key')
module kvKms '../modules/security/keyvault/main.bicep' = if (keyVaultKmsCreateAndPrereqs) {
  name: take('${deployment().name}-keyvaultKms-${resourceName}', 64)
  params: {
    resourceName: take('kms${resourceName}', 20)
    keyVaultPurgeProtection: keyVaultPurgeProtection
    keyVaultSoftDelete: keyVaultSoftDelete
    location: location
    privateLinks: privateLinks
  }
}

module kvKmsCreatedRbac '../modules/security/keyvault/keyvault-rbac.bicep' = if (keyVaultKmsCreateAndPrereqs) {
  name: take('${deployment().name}-keyvaultKmsRbacs-${resourceName}', 64)
  params: {
    keyVaultName: keyVaultKmsCreate ? kvKms.outputs.keyVaultName : ''
    //We can't create a kms kv and key and do privatelink. Private Link is a BYO scenario
    // rbacKvContributorSps : [
    //   createAksUai && privateLinks ? aksUai.properties.principalId : ''
    // ]
    //This allows the Aks Cluster to access the key vault key
    rbacCryptoUserSps: [
      aksPrincipalId
    ]
    //This allows the Deploying user to create the key vault key
    rbacCryptoOfficerUsers: [
      !empty(keyVaultKmsOfficerRolePrincipalId) && !automatedDeployment ? keyVaultKmsOfficerRolePrincipalId : ''
    ]
    //This allows the Deploying sp to create the key vault key
    rbacCryptoOfficerSps: [
      !empty(keyVaultKmsOfficerRolePrincipalId) && automatedDeployment ? keyVaultKmsOfficerRolePrincipalId : ''
    ]
  }
}

module kvKmsByoRbac '../modules/security/keyvault/keyvault-rbac.bicep' = if (!empty(keyVaultKmsByoKeyId)) {
  name: take('${resourceName}-${deployment().name}-keyvaultKmsByoRbacs', 64)
  scope: resourceGroup(keyVaultKmsByoRG)
  params: {
    keyVaultName: kvKmsByo.name
    //Contribuor allows AKS to create the private link
    rbacKvContributorSps: [
      privateLinks ? aksPrincipalId : ''
    ]
    //This allows the Aks Cluster to access the key vault key
    rbacCryptoUserSps: [
      aksPrincipalId
    ]
  }
}

@description('It can take time for the RBAC to propagate, this delays the deployment to avoid this problem')
module waitForKmsRbac 'br/public:deployment-scripts/wait:1.0.1' = if (keyVaultKmsCreateAndPrereqs && kmsRbacWaitSeconds > 0) {
  name: take('${resourceName}-${deployment().name}-keyvaultKmsRbac-waits', 64)
  params: {
    waitSeconds: kmsRbacWaitSeconds
    location: location
  }
  dependsOn: [
    kvKmsCreatedRbac
  ]
}

@description('Adding a key to the keyvault. We can only do this for public key vaults')
module kvKmsKey '../modules/security/keyvault/keyvaultkey.bicep' = if (keyVaultKmsCreateAndPrereqs) {
  name: take('${deployment().name}-keyvaultKmsKeys-${resourceName}', 64)
  params: {
    keyVaultName: keyVaultKmsCreateAndPrereqs ? kvKms.outputs.keyVaultName : ''
  }
  dependsOn: [waitForKmsRbac]
}

var azureKeyVaultKms = {
  securityProfile: {
    azureKeyVaultKms: {
      enabled: keyVaultKmsCreateAndPrereqs || !empty(keyVaultKmsByoKeyId)
      keyId: keyVaultKmsCreateAndPrereqs
        ? kvKmsKey.outputs.keyVaultKmsKeyUri
        : !empty(keyVaultKmsByoKeyId) ? keyVaultKmsByoKeyId : ''
      keyVaultNetworkAccess: privateLinks ? 'private' : 'public'
      keyVaultResourceId: privateLinks && !empty(keyVaultKmsByoKeyId) ? kvKmsByo.id : ''
    }
  }
}

@description('The name of the Kms Key Vault')
output keyVaultKmsName string = keyVaultKmsCreateAndPrereqs
  ? kvKms.outputs.keyVaultName
  : !empty(keyVaultKmsByoKeyId) ? keyVaultKmsByoName : ''

@description('Indicates if the user has supplied all the correct parameter to use a AKSC Created KMS')
output kmsCreatePrerequisitesMet bool = keyVaultKmsCreateAndPrereqs

// 4. Container Registry
@allowed([
  ''
  'Basic'
  'Standard'
  'Premium'
])
@description('The SKU to use for the Container Registry')
param registries_sku string = ''

@description('Enable the ACR Content Trust Policy, SKU must be set to Premium')
param enableACRTrustPolicy bool = false
var acrContentTrustEnabled = enableACRTrustPolicy && registries_sku == 'Premium' ? 'enabled' : 'disabled'

//param enableACRZoneRedundancy bool = true
var acrZoneRedundancyEnabled = !empty(availabilityZones) && registries_sku == 'Premium' ? 'Enabled' : 'Disabled'

@description('Enable removing of untagged manifests from ACR')
param acrUntaggedRetentionPolicyEnabled bool = false

@description('The number of days to retain untagged manifests for')
param acrUntaggedRetentionPolicy int = 30

var acrName = 'cr${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (!empty(registries_sku)) {
  name: acrName
  location: location
  sku: {
    #disable-next-line BCP036 //Disabling validation of this parameter to cope with empty string to indicate no ACR required.
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
            status: 'enabled'
            days: acrUntaggedRetentionPolicy
          }
        : null
    }
    publicNetworkAccess: privateLinks /* && empty(acrIPWhitelist)*/ ? 'Disabled' : 'Enabled'
    zoneRedundancy: acrZoneRedundancyEnabled
    /*
    networkRuleSet: {
      defaultAction: 'Deny'

      ipRules: empty(acrIPWhitelist) ? [] : [
          {
            action: 'Allow'
            value: acrIPWhitelist
        }
      ]
      virtualNetworkRules: []
    }
    */
  }
}
output containerRegistryName string = !empty(registries_sku) ? acr.name : ''
output containerRegistryId string = !empty(registries_sku) ? acr.id : ''

resource acrDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (createLaw && !empty(registries_sku)) {
  name: 'acrDiags'
  scope: acr
  properties: {
    workspaceId: aks_law.outputs.id
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        timeGrain: 'PT1M'
      }
    ]
  }
}

module acrPool '../modules/containers/acr/acragentpool.bicep' = if (custom_vnet && (!empty(registries_sku)) && privateLinks && acrPrivatePool) {
  name: take('${deployment().name}-acrprivatepool', 64)
  params: {
    acrName: acr.name
    acrPoolSubnetId: custom_vnet ? network.outputs.acrPoolSubnetId : ''
    location: location
  }
}

module aks_acr_pull '../modules/rbac/acrpullrole.bicep' = if (!empty(registries_sku)) {
  params: {
    acrName: acr.name
    aksName: aks.name
    registries_sku: registries_sku
  }
}

@description('The principal ID of the service principal to assign the push role to the ACR')
param acrPushRolePrincipalId string = ''

module aks_acr_push '../modules/rbac/acrpushrole.bicep' = {
  params: {
    acrName: acr.name
    aksName: aks.name
    registries_sku: registries_sku
    automatedDeployment: automatedDeployment
    acrPushRolePrincipalId: acrPushRolePrincipalId
  }
}

param imageNames array = []

module acrImport 'br/public:deployment-scripts/import-acr:3.0.1' = if (!empty(registries_sku) && !empty(imageNames)) {
  name: take('${deployment().name}-AcrImport', 64)
  params: {
    acrName: acr.name
    location: location
    images: imageNames
    managedIdentityName: 'id-acrImport-${resourceName}-${location}'
  }
}

// 5. Firewall
@description('Create an Azure Firewall, requires custom_vnet')
param azureFirewalls bool = false

@description('Add application rules to the firewall for certificate management.')
param certManagerFW bool = false

@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param azureFirewallSku string = 'Standard'

module firewall '../modules/networking/firewall/main.bicep' = if (azureFirewalls && custom_vnet) {
  name: take('${deployment().name}-firewall', 64)
  params: {
    resourceName: resourceName
    location: location
    workspaceDiagsId: createLaw ? aks_law.outputs.id : ''
    fwSubnetId: azureFirewalls && custom_vnet ? network.outputs.fwSubnetId : ''
    fwSku: azureFirewallSku
    fwManagementSubnetId: azureFirewalls && custom_vnet && azureFirewallSku == 'Basic'
      ? network.outputs.fwMgmtSubnetId
      : ''
    vnetAksSubnetAddressPrefix: vnetAksSubnetAddressPrefix
    certManagerFW: certManagerFW
    appDnsZoneName: !empty(dnsZoneId) ? split(dnsZoneId, '/')[8] : ''
    acrPrivatePool: acrPrivatePool
    acrAgentPoolSubnetAddressPrefix: acrAgentPoolSubnetAddressPrefix
    // inboundHttpFW: inboundHttpFW
    availabilityZones: availabilityZones
  }
}

// 6. Application Gateway
@description('Create an Application Gateway')
param ingressApplicationGateway bool = false

@description('The number of applciation gateway instances')
param appGWcount int = 2

@description('The maximum number of application gateway instances')
param appGWmaxCount int = 0

@maxLength(15)
@description('A known private ip in the Application Gateway subnet range to be allocated for internal traffic')
param privateIpApplicationGateway string = ''

@description('Enable key vault integration for application gateway')
param appgwKVIntegration bool = false

@allowed([
  'Standard_v2'
  'WAF_v2'
])
@description('The SKU for AppGw')
param appGWsku string = 'WAF_v2'

@description('Enable the WAF Firewall, valid for WAF_v2 SKUs')
param appGWenableFirewall bool = true

var deployAppGw = ingressApplicationGateway && (custom_vnet || !empty(byoAGWSubnetId))
var appGWenableWafFirewall = appGWsku == 'Standard_v2' ? false : appGWenableFirewall

// If integrating App Gateway with KeyVault, create an Identity App Gateway will use to access keyvault
// 'identity' is always created (adding: "|| deployAppGw") until this is fixed:
// https://github.com/Azure/bicep/issues/387#issuecomment-885671296
resource appGwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (deployAppGw) {
  name: '${resourceName}-id-appgw'
  location: location
}

var appgwName = '${resourceName}-agw'
var appgwResourceId = deployAppGw ? resourceId('Microsoft.Network/applicationGateways', '${appgwName}') : ''

resource appgwpip 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (deployAppGw) {
  name: '${resourceName}-pip-agw'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: !empty(availabilityZones) ? availabilityZones : []
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

var frontendPublicIpConfig = {
  properties: {
    publicIPAddress: {
      id: appgwpip.id
    }
  }
  name: 'appGatewayFrontendIP'
}

var frontendPrivateIpConfig = {
  properties: {
    privateIPAllocationMethod: 'Static'
    privateIPAddress: privateIpApplicationGateway
    subnet: {
      id: appGwSubnetId
    }
  }
  name: 'appGatewayPrivateIP'
}

@allowed([
  'Prevention'
  'Detection'
])
param appGwFirewallMode string = 'Prevention'

var appGwFirewallConfigOwasp = {
  enabled: appGWenableWafFirewall
  firewallMode: appGwFirewallMode
  ruleSetType: 'OWASP'
  ruleSetVersion: '3.2'
  requestBodyCheck: true
  maxRequestBodySizeInKb: 128
  disabledRuleGroups: []
}

var appGWskuObj = union(
  {
    name: appGWsku
    tier: appGWsku
  },
  appGWmaxCount == 0
    ? {
        capacity: appGWcount
      }
    : {}
)

// weed to create a variable with the app gateway properies, because of the conditional key 'autoscaleConfiguration'
var appgwProperties = union(
  {
    sku: appGWskuObj
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20170401S'
    }
    webApplicationFirewallConfiguration: appGWenableWafFirewall ? appGwFirewallConfigOwasp : json('null')
    gatewayIPConfigurations: [
      {
        name: 'besubnet'
        properties: {
          subnet: {
            id: appGwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: empty(privateIpApplicationGateway)
      ? array(frontendPublicIpConfig)
      : concat(array(frontendPublicIpConfig), array(frontendPrivateIpConfig))
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultaddresspool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaulthttpsetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: 'hlisten'
        properties: {
          frontendIPConfiguration: {
            id: empty(privateIpApplicationGateway)
              ? '${appgwResourceId}/frontendIPConfigurations/appGatewayFrontendIP'
              : '${appgwResourceId}/frontendIPConfigurations/appGatewayPrivateIP'
          }
          frontendPort: {
            id: '${appgwResourceId}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appGwRoutingRuleName'
        properties: {
          ruleType: 'Basic'
          priority: '1'
          httpListener: {
            id: '${appgwResourceId}/httpListeners/hlisten'
          }
          backendAddressPool: {
            id: '${appgwResourceId}/backendAddressPools/defaultaddresspool'
          }
          backendHttpSettings: {
            id: '${appgwResourceId}/backendHttpSettingsCollection/defaulthttpsetting'
          }
        }
      }
    ]
  },
  appGWmaxCount > 0
    ? {
        autoscaleConfiguration: {
          minCapacity: appGWcount
          maxCapacity: appGWmaxCount
        }
      }
    : {}
)

// 'identity' is always set until this is fixed: https://github.com/Azure/bicep/issues/387#issuecomment-885671296
resource appgw 'Microsoft.Network/applicationGateways@2024-10-01' = if (deployAppGw) {
  name: appgwName
  location: location
  zones: !empty(availabilityZones) ? availabilityZones : []
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGwIdentity.id}': {}
    }
  }
  properties: appgwProperties
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-template#new-service-principal
// AGIC's identity requires "Contributor" permission over Application Gateway.
module appGwAGICContrib '../modules/rbac/appgatewaycontributor.bicep' = {
  params: {
    aksName: aks.name
    appGatewayName: appgw.name
    ingressApplicationGateway: ingressApplicationGateway
    deployAppGw: deployAppGw
  }
}

// AGIC's identity requires "Reader" permission over Application Gateway's resource group.
module appGwAGICRGReader '../modules/rbac/appgatewayreader.bicep' = {
  params: {
    aksName: aks.name
    ingressApplicationGateway: ingressApplicationGateway
    deployAppGw: deployAppGw
  }
}

module appGwAGICMIOp '../modules/rbac/appgatewaymanagedidentityoperator.bicep' = {
  params: {
    aksName: aks.name
    appGatewayManagedIdentityName: appGwIdentity.name
    ingressApplicationGateway: ingressApplicationGateway
    deployAppGw: deployAppGw
  }
}

// AppGW Diagnostics
resource appgw_Diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (createLaw && deployAppGw) {
  scope: appgw
  name: 'appgwDiag'
  properties: {
    workspaceId: aks_law.outputs.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
  }
}

output ApplicationGatewayName string = deployAppGw ? appgw.name : ''

// 7. AKS
@description('DNS prefix. Defaults to {resourceName}-dns')
param dnsPrefix string = '${resourceName}-dns'

@description('Kubernetes Version')
param kubernetesVersion string = '1.29.7'

@description('Enable Azure AD integration on AKS')
param enable_aad bool = false

@description('The ID of the Azure AD tenant')
param aad_tenant_id string = ''

@description('Create, and use a new Log Analytics workspace for AKS logs')
param omsagent bool = false

@description('Enables the ContainerLogsV2 table to be of type Basic')
param containerLogsV2BasicLogs bool = false

@description('Enable RBAC using AAD')
param enableAzureRBAC bool = false

@description('Enables Kubernetes Event-driven Autoscaling (KEDA)')
param kedaAddon bool = false

@description('Enables Open Service Mesh')
param openServiceMeshAddon bool = false

@description('Enables SGX Confidential Compute plugin')
param sgxPlugin bool = false

@description('Enables the Blob CSI driver')
param blobCSIDriver bool = false

@description('Enables the File CSI driver')
param fileCSIDriver bool = true

@description('Enables the Disk CSI driver')
param diskCSIDriver bool = true

@allowed([
  'none'
  'patch'
  'stable'
  'rapid'
  'node-image'
])
@description('AKS upgrade channel')
param upgradeChannel string = 'none'

@allowed([
  'Ephemeral'
  'Managed'
])
@description('OS disk type')
param osDiskType string = 'Ephemeral'

@description('VM SKU')
param agentVMSize string = 'Standard_D4ds_v5'

@description('Disk size in GB')
param osDiskSizeGB int = 0

@description('The number of agents for the user node pool')
param agentCount int = 3

@description('The maximum number of nodes for the user node pool')
param agentCountMax int = 0
var autoScale = agentCountMax > agentCount

@minLength(3)
@maxLength(12)
@description('Name for user node pool')
param nodePoolName string = 'userpool01'

@description('Config the user node pool as a spot instance')
param nodePoolSpot bool = false

@description('Allocate pod ips dynamically')
param cniDynamicIpAllocation bool = false

@minValue(10)
@maxValue(250)
@description('The maximum number of pods per node.')
param maxPods int = 30

@allowed([
  'azure'
  'kubenet'
])
@description('The network plugin type')
param networkPlugin string = 'azure'

@allowed([
  ''
  'Overlay'
])
@description('The network plugin type')
param networkPluginMode string = ''

@allowed([
  ''
  'cilium'
])
@description('Use Cilium dataplane (requires azure networkPlugin)')
param networkDataplane string = ''

@allowed([
  ''
  'azure'
  'calico'
  'cilium'
])
@description('The network policy to use.')
param networkPolicy string = ''

@allowed([
  ''
  'audit'
  'deny'
])
@description('Enable the Azure Policy addon')
param azurepolicy string = ''

@allowed([
  'Baseline'
  'Restricted'
])
param azurePolicyInitiative string = 'Baseline'

@description('The IP addresses that are allowed to access the API server')
param authorizedIPRanges array = []

@description('Enable private cluster')
param enablePrivateCluster bool = false

@allowed([
  'system'
  'none'
  'privateDnsZone'
])
@description('Private cluster dns advertisment method, leverages the dnsApiPrivateZoneId parameter')
param privateClusterDnsMethod string = 'system'

@description('The full Azure resource ID of the privatelink DNS zone to use for the AKS cluster API Server')
param dnsApiPrivateZoneId string = ''

@description('The zones to use for a node pool')
param availabilityZones array = []

@description('Disable local K8S accounts for AAD enabled clusters')
param AksDisableLocalAccounts bool = false

@description('Use the paid sku for SLA rather than SLO')
param AksPaidSkuForSLA bool = false

@minLength(9)
@maxLength(18)
@description('The address range to use for pods')
param podCidr string = '10.240.100.0/22'

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string = '172.10.0.0/16'

@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string = '172.10.0.10'

@description('Enable Microsoft Defender for Containers (preview)')
param defenderForContainers bool = false

@description('Only use the system node pool')
param JustUseSystemPool bool = false

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
  'Custom'
])
@description('The System Pool Preset sizing')
param SystemPoolType string = 'CostOptimised'

@description('A custom system pool spec')
param SystemPoolCustomPreset object = {}

param AutoscaleProfile object = {
  'balance-similar-node-groups': 'true'
  expander: 'random'
  'max-empty-bulk-delete': '10'
  'max-graceful-termination-sec': '600'
  'max-node-provision-time': '15m'
  'max-total-unready-percentage': '45'
  'new-pod-scale-up-delay': '0s'
  'ok-total-unready-count': '3'
  'scale-down-delay-after-add': '10m'
  'scale-down-delay-after-delete': '20s'
  'scale-down-delay-after-failure': '3m'
  'scale-down-unneeded-time': '10m'
  'scale-down-unready-time': '20m'
  'scale-down-utilization-threshold': '0.5'
  'scan-interval': '10s'
  'skip-nodes-with-local-storage': 'true'
  'skip-nodes-with-system-pods': 'true'
}

@allowed([
  'loadBalancer'
  'natGateway'
  'userDefinedRouting'
])
@description('Outbound traffic type for the egress traffic of your cluster')
param aksOutboundTrafficType string = 'loadBalancer'

@description('Create a new Nat Gateway, applies to custom networking only')
param createNatGateway bool = false

@minValue(1)
@maxValue(16)
@description('The effective outbound IP resources of the cluster NAT gateway')
param natGwIpCount int = 2

@minValue(4)
@maxValue(120)
@description('Outbound flow idle timeout in minutes for NatGw')
param natGwIdleTimeout int = 30

@description('Configures the cluster as an OIDC issuer for use with Workload Identity')
param oidcIssuer bool = false

@description('Installs Azure Workload Identity into the cluster')
param workloadIdentity bool = false

@description('Assign a public IP per node for user node pools')
param enableNodePublicIP bool = false

param warIngressNginx bool = false

@maxLength(80)
@description('The name of the NEW resource group to create the AKS cluster managed resources in')
param managedNodeResourceGroup string = ''

// Preview feature requires: az feature register --namespace "Microsoft.ContainerService" --name "NRGLockdownPreview"
@allowed([
  'ReadOnly'
  'Unrestricted'
])
@description('The restriction level applied to the cluster node resource group')
param restrictionLevelNodeResourceGroup string = 'Unrestricted'

@allowed(['', 'Istio'])
@description('The service mesh profile to use')
param serviceMeshProfile string = ''

@description('The ingress gateway to use for the Istio service mesh')
param istioIngressGatewayMode string = ''
param istioRevision string = 'asm-1-20'

var serviceMeshProfileObj = {
  istio: {
    components: {
      ingressGateways: empty(istioIngressGatewayMode)
        ? null
        : [
            {
              enabled: true
              mode: istioIngressGatewayMode
            }
          ]
    }
    revisions: [
      istioRevision
    ]
  }
  mode: 'Istio'
}

@description('This resolves the friendly natGateway to the actual outbound traffic type value used by AKS')
var outboundTrafficType = aksOutboundTrafficType == 'natGateway'
  ? (custom_vnet ? 'userAssignedNATGateway' : 'managedNATGateway')
  : aksOutboundTrafficType

@description('System Pool presets are derived from the recommended system pool specs')
var systemPoolPresets = {
  CostOptimised: {
    vmSize: 'Standard_B4s_v2'
    count: 1
    minCount: 1
    maxCount: 3
    enableAutoScaling: true
    availabilityZones: []
  }
  Standard: {
    vmSize: 'Standard_D4ds_v5'
    count: 3
    minCount: 3
    maxCount: 5
    enableAutoScaling: true
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
  HighSpec: {
    vmSize: 'Standard_D8ds_v4'
    count: 3
    minCount: 3
    maxCount: 5
    enableAutoScaling: true
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
}

var systemPoolBase = {
  name: JustUseSystemPool ? nodePoolName : 'agentpool'
  vmSize: agentVMSize
  count: agentCount
  mode: 'System'
  osType: 'Linux'
  osSku: osSKU == 'AzureLinux' ? osSKU : 'Ubuntu'
  maxPods: 30
  type: 'VirtualMachineScaleSets'
  vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
  podSubnetID: !empty(aksPodSubnetId) ? aksPodSubnetId : null
  upgradeSettings: {
    maxSurge: '33%'
  }
  nodeTaints: [
    JustUseSystemPool ? '' : 'CriticalAddonsOnly=true:NoSchedule'
  ]
}

var agentPoolProfiles = JustUseSystemPool
  ? array(systemPoolBase)
  : concat(array(union(
      systemPoolBase,
      SystemPoolType == 'Custom' && SystemPoolCustomPreset != {}
        ? SystemPoolCustomPreset
        : systemPoolPresets[SystemPoolType]
    )))

output userNodePoolName string = nodePoolName
output systemNodePoolName string = JustUseSystemPool ? nodePoolName : 'agentpool'

var akssku = AksPaidSkuForSLA ? 'Standard' : 'Free'

var aks_addons = union(
  {
    azurepolicy: {
      config: {
        version: !empty(azurepolicy) ? 'v2' : json('null')
      }
      enabled: !empty(azurepolicy)
    }
    azureKeyvaultSecretsProvider: {
      config: {
        enableSecretRotation: 'true'
        rotationPollInterval: keyVaultAksCSIPollInterval
      }
      enabled: keyVaultAksCSI
    }
    openServiceMesh: {
      enabled: openServiceMeshAddon
      config: {}
    }
    ACCSGXDevicePlugin: {
      enabled: sgxPlugin
      config: {}
    }
  },
  createLaw && omsagent
    ? {
        omsagent: {
          enabled: createLaw && omsagent
          config: {
            logAnalyticsWorkspaceResourceID: createLaw && omsagent ? aks_law.outputs.id : json('null')
          }
        }
      }
    : {}
)

var aks_addons1 = ingressApplicationGateway
  ? union(
      aks_addons,
      deployAppGw
        ? {
            ingressApplicationGateway: {
              config: {
                applicationGatewayId: appgw.id
              }
              enabled: true
            }
          }
        : {
            // AKS RP will deploy the AppGateway for us (not creating custom or BYO VNET)
            ingressApplicationGateway: {
              enabled: true
              config: {
                applicationGatewayName: appgwName
                subnetCIDR: '10.225.0.0/16'
              }
            }
          }
    )
  : aks_addons

@description('Sets the private dns zone id if provided')
var aksPrivateDnsZone = privateClusterDnsMethod == 'privateDnsZone'
  ? (!empty(dnsApiPrivateZoneId) ? dnsApiPrivateZoneId : 'system')
  : privateClusterDnsMethod
output aksPrivateDnsZone string = aksPrivateDnsZone
output privateFQDN string = enablePrivateCluster && privateClusterDnsMethod != 'none'
  ? aks.outputs.properties.privateFQDN
  : ''
// Dropping cluster name at start of privateFQDN to get private dns zone name.
output aksPrivateDnsZoneName string = enablePrivateCluster && privateClusterDnsMethod != 'none'
  ? join(skip(split(aks.outputs.properties.privateFQDN, '.'), 1), '.')
  : ''

@description('Needing to seperately declare and union this because of https://github.com/Azure/AKS-Construction/issues/344')
var managedNATGatewayProfile = {
  networkProfile: {
    natGatewayProfile: {
      managedOutboundIPProfile: {
        count: natGwIpCount
      }
      idleTimeoutInMinutes: natGwIdleTimeout
    }
  }
}

@description('Needing to seperately declare and union this because of https://github.com/Azure/AKS/issues/2774')
var azureDefenderSecurityProfile = {
  securityProfile: {
    defender: {
      logAnalyticsWorkspaceResourceId: createLaw ? aks_law.outputs.id : null
      securityMonitoring: {
        enabled: defenderForContainers
      }
    }
  }
}

var aksProperties = union(
  {
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    dnsPrefix: dnsPrefix
    aadProfile: enable_aad
      ? {
          managed: true
          enableAzureRBAC: enableAzureRBAC
          tenantID: aad_tenant_id
        }
      : null
    apiServerAccessProfile: !empty(authorizedIPRanges)
      ? {
          authorizedIPRanges: createNatGateway
            ? concat(authorizedIPRanges, network.outputs.natGwIpArr)
            : authorizedIPRanges
        }
      : {
          enablePrivateCluster: enablePrivateCluster
          privateDNSZone: enablePrivateCluster ? aksPrivateDnsZone : ''
          enablePrivateClusterPublicFQDN: enablePrivateCluster && privateClusterDnsMethod == 'none'
        }
    agentPoolProfiles: agentPoolProfiles
    workloadAutoScalerProfile: {
      keda: {
        enabled: kedaAddon
      }
    }
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      #disable-next-line BCP036 //Disabling validation of this parameter to cope with empty string to indicate no Network Policy required.
      networkPolicy: networkPolicy
      networkPluginMode: networkPlugin == 'azure' ? networkPluginMode : ''
      podCidr: networkPlugin == 'kubenet' || networkPluginMode == 'Overlay' || cniDynamicIpAllocation
        ? podCidr
        : json('null')
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      outboundType: outboundTrafficType
      networkDataplane: networkPlugin == 'azure' ? networkDataplane : ''
    }
    disableLocalAccounts: AksDisableLocalAccounts && enable_aad
    autoUpgradeProfile: { upgradeChannel: upgradeChannel }
    addonProfiles: !empty(aks_addons1) ? aks_addons1 : aks_addons
    autoScalerProfile: autoScale ? AutoscaleProfile : {}
    oidcIssuerProfile: {
      enabled: oidcIssuer
    }
    securityProfile: {
      workloadIdentity: {
        enabled: workloadIdentity
      }
    }
    ingressProfile: {
      webAppRouting: {
        enabled: warIngressNginx
      }
    }
    storageProfile: {
      blobCSIDriver: {
        enabled: blobCSIDriver
      }
      diskCSIDriver: {
        enabled: diskCSIDriver
      }
      fileCSIDriver: {
        enabled: fileCSIDriver
      }
    }
  },
  outboundTrafficType == 'managedNATGateway' ? managedNATGatewayProfile : {},
  defenderForContainers && createLaw ? azureDefenderSecurityProfile : {},
  keyVaultKmsCreateAndPrereqs || !empty(keyVaultKmsByoKeyId) ? azureKeyVaultKms : {},
  !empty(managedNodeResourceGroup) ? { nodeResourceGroup: managedNodeResourceGroup } : {},
  !empty(serviceMeshProfile) ? { serviceMeshProfile: serviceMeshProfileObj } : {}
)

module aks '../modules/compute/aks/main.bicep' = {
  params: {
    resourceName: resourceName
    location: location
    aksProperties: aksProperties
    createAksUai: createAksUai
    aksUai: aksUai
    byoUaiName: byoUaiName
    byoAksUai: byoAksUai
    akssku: akssku
    oidcIssuer: oidcIssuer
  }
  dependsOn: [
    kvKmsKey
    waitForKmsRbac
  ]
}

@allowed(['Linux', 'Windows'])
@description('The User Node pool OS')
param osType string = 'Linux'

@allowed(['AzureLinux', 'Ubuntu', 'Windows2019', 'Windows2022'])
@description('User Node pool OS SKU')
param osSKU string = 'Ubuntu'

var poolName = osType == 'Linux' ? nodePoolName : take(nodePoolName, 6)

// Default OS Disk Size in GB for Linux is 30, for Windows is 100
var defaultOsDiskSizeGB = 128

module userNodePool '../modules/compute/aks/aksagentpool.bicep' = if (!JustUseSystemPool) {
  name: take('${deployment().name}-userNodePool', 64)
  params: {
    aksName: aks.outputs.aksClusterName
    poolName: poolName
    subnetId: aksSubnetId
    podSubnetID: !empty(aksPodSubnetId) ? aksPodSubnetId : ''
    agentCount: agentCount
    agentCountMax: agentCountMax
    agentVMSize: agentVMSize
    maxPods: maxPods
    osDiskType: osDiskType
    osType: osType
    osSKU: osSKU
    enableNodePublicIP: enableNodePublicIP
    osDiskSizeGB: osDiskSizeGB == 0 ? defaultOsDiskSizeGB : osDiskSizeGB
    availabilityZones: availabilityZones
    spotInstance: nodePoolSpot
  }
}

@description('Not giving Rbac at the vnet level when using private dns results in ReconcilePrivateDNS. Therefore we need to upgrade the scope when private dns is being used, because it wants to set up the dns->vnet integration.')
var uaiNetworkScopeRbac = enablePrivateCluster && !empty(dnsApiPrivateZoneId) ? 'Vnet' : 'Subnet'
module privateDnsZoneRbac '../modules/dns/dnsZoneRbac.bicep' = if (enablePrivateCluster && !empty(dnsApiPrivateZoneId) && createAksUai) {
  name: take('${deployment().name}-addPrivateK8sApiDnsContributor', 64)
  params: {
    vnetId: ''
    dnsZoneId: dnsApiPrivateZoneId
    principalId: aksPrincipalId
  }
}

module aks_policies '../modules/compute/aks/akspolicies.bicep' = {
  name: take('${deployment().name}-akspolicies', 64)
  params: {
    resourceName: resourceName
    azurepolicy: azurepolicy
    location: location
    azurePolicyInitiative: azurePolicyInitiative
  }
}

@description('If automated deployment, for the 3 automated user assignments, set Principal Type on each to "ServicePrincipal" rarter than "User"')
param automatedDeployment bool = false

@description('The principal ID to assign the AKS admin role.')
param adminPrincipalId string = ''

module aks_admin_role_assignment '../modules/compute/aks/aksrole.bicep' = {
  params: {
    enableAzureRBAC: enableAzureRBAC
    existingAksName: aks.outputs.aksClusterName
    adminPrincipalId: adminPrincipalId
    automatedDeployment: automatedDeployment
  }
}

param fluxGitOpsAddOn bool = false

module aks_flux_gitops '../modules/compute/aks/aksfluxaddon.bicep' = {
  params: {
    existingAksName: aks.outputs.aksClusterName
    fluxGitOpsAddOn: fluxGitOpsAddOn
  }
  dependsOn: [daprExtensions] //Chaining dependencies because of: https://github.com/Azure/AKS-Construction/issues/385
}

@description('Add the Dapr extension')
param daprAddon bool = false
@description('Enable high availability (HA) mode for the Dapr control plane')
param daprAddonHA bool = false

module daprExtensions '../modules/compute/aks/aksdapr.bicep' = {
  params: {
    existingAksName: aks.outputs.aksClusterName
    daprAddon: daprAddon
    daprAddonHA: daprAddonHA
  }
}

// 8. Monitoring / Log Analytics
@description('Diagnostic categories to log')
param aksDiagCategories array = [
  'cluster-autoscaler'
  'kube-controller-manager'
  'kube-audit-admin'
  'guard'
]

@description('Enable SysLogs and send to log analytics')
param enableSysLog bool = false

module aks_diagnostics '../modules/monitoring/diagnostic-settings/aksdiagnosticsettings.bicep' = {
  params: {
    diagnosticName: take('${deployment().name}-aksdiagnostics', 64)
    existingAksName: aks.outputs.aksClusterName
    createLaw: createLaw
    workSpaceId: aks_law.outputs.id
    isAnotherResourceCreated: omsagent
    diagnosticCategories: aksDiagCategories
  }
}

module sysLog '../modules/monitoring/data-collection/main.bicep' = {
  params: {
    name: aks.outputs.aksClusterName
    aksLawId: aks_law.outputs.id
    location: location
    createLaw: createLaw
    isAnotherResourceCreated: omsagent
    enableSysLog: enableSysLog
  }
}

@description('Enable Metric Alerts')
param createAksMetricAlerts bool = true

@allowed([
  'Short'
  'Long'
])
@description('Which Metric polling frequency model to use')
param aksMetricAlertMetricFrequencyModel string = 'Long'

var alertFrequencyLookup = {
  Short: {
    evalFrequency: 'PT1M'
    windowSize: 'PT5M'
  }
  Long: {
    evalFrequency: 'PT15M'
    windowSize: 'PT1H'
  }
}
var alertFrequency = alertFrequencyLookup[aksMetricAlertMetricFrequencyModel]

module aks_metric_alerts '../modules/compute/aks/aksmetricalerts.bicep' = if (createLaw) {
  name: take('${deployment().name}-aksmetricalerts', 64)
  scope: resourceGroup()
  params: {
    clusterName: aks.name
    logAnalyticsWorkspaceName: aks_law.name
    metricAlertsEnabled: createAksMetricAlerts
    evalFrequency: alertFrequency.evalFrequency
    windowSize: alertFrequency.windowSize
    alertSeverity: 'Informational'
    logAnalyticsWorkspaceLocation: location
  }
}

// Container Insights
@description('The Log Analytics retention period')
param retentionInDays int = 30

@description('The Log Analytics daily data cap (GB) (0=no limit)')
param logDataCap int = 0

var aks_law_name = 'log-${resourceName}'

var createLaw = (omsagent || deployAppGw || azureFirewalls || CreateNetworkSecurityGroups || defenderForContainers)

module aks_law '../modules/monitoring/log-analytics-workspace/main.bicep' = {
  params: {
    lawName: aks_law_name
    createLaw: createLaw
    location: location
    retentionInDays: retentionInDays
    logDataCap: logDataCap
  }
}

module containerLogsV2_BasicLogs '../modules/monitoring/log-analytics-workspace/tables/main.bicep' = {
  params: {
    aksName: aks.outputs.aksClusterName
    logAnalyticsWorkspaceName: aks_law_name
    tableName: 'ContainerLogsV2'
    enableBasicLogs: containerLogsV2BasicLogs
  }
}

module fastAlertingRoleLaw '../modules/compute/aks/aksfastlartingrolelaw.bicep' = {
  params: {
    existingAksName: aks.outputs.aksClusterName
    aksLawName: aks_law_name
    createLaw: createLaw
    omsagent: omsagent
  }
}

// AKS events with eventgrid
// Supported events : https://docs.microsoft.com/en-gb/azure/event-grid/event-schema-aks?tabs=event-grid-event-schema#available-event-types
@description('Create an Event Grid System Topic for AKS events')
param createEventGrid bool = false

module eventGrid '../modules/eventing/eventgrid/main.bicep' = {
  params: {
    name: aks.name
    location: location
    sourceId: aks.outputs.id
    createEventGrid: createEventGrid
    topicType: 'Microsoft.ContainerService.ManagedClusters'
  }
}

module eventGridDiagnostics '../modules/monitoring/diagnostic-settings/eventgriddiagnosticsettings.bicep' = if (createEventGrid && createLaw) {
  params: {
    name: take('${deployment().name}-egdiagnostics', 64)
    eventGridName: eventGrid.outputs.eventGridName
    workspaceId: aks_law.outputs.id
    createLaw: createLaw
    createEventGrid: createEventGrid
  }
}

// 9. Telemetry

@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true

var telemetryId = '${guid(subscription().subscriptionId, resourceName, location)}-${location}'

module telemetrydeployment '../modules/telemetry/main.bicep' = if (enableTelemetry) {
  // name: take('${deployment().name}-telemetry', 64)
  params: {
    telemetryId: telemetryId
    enableTelemetry: enableTelemetry
  }
}

// Automation
@allowed(['', 'Weekday', 'Day'])
@description('Creates an Azure Automation Account to provide scheduled start and stop of the cluster')
@metadata({ category: 'Automation' })
param automationAccountScheduledStartStop string = ''

@description('The IANA time zone of the automation account')
@metadata({ category: 'Automation' })
param automationTimeZone string = 'Etc/UTC'

@minValue(0)
@maxValue(23)
@description('When to start the cluster')
@metadata({ category: 'Automation' })
param automationStartHour int = 8

@minValue(0)
@maxValue(23)
@description('When to stop the cluster')
@metadata({ category: 'Automation' })
param automationStopHour int = 19

var automationFrequency = automationAccountScheduledStartStop == 'Day' ? 'Day' : 'Weekday'

module aksStartstop 'automationrunbook/automation.bicep' = if (!empty(automationAccountScheduledStartStop)) {
  name: take('${deployment().name}-aksstartstop', 64)
  params: {
    location: location
    automationAccountName: '${resourceName}-aa'
    runbookName: 'aks-cluster-changestate'
    runbookUri: 'https://raw.githubusercontent.com/finoops/aks-cluster-changestate/main/aks-cluster-changestate.ps1'
    runbookType: 'Script'
    timezone: automationTimeZone
    schedulesToCreate: [
      {
        frequency: automationFrequency
        hour: automationStartHour
        minute: 0
      }
      {
        frequency: automationFrequency
        hour: automationStopHour
        minute: 0
      }
    ]
    runbookJobSchedule: [
      {
        scheduleName: '${automationFrequency} - ${padLeft(automationStartHour, 2, '0')}:00'
        parameters: {
          ResourceGroupName: resourceGroup().name
          AksClusterName: aks.name
          Operation: 'start'
        }
      }
      {
        scheduleName: '${automationFrequency} - ${padLeft(automationStopHour, 2, '0')}:00'
        parameters: {
          ResourceGroupName: resourceGroup().name
          AksClusterName: aks.name
          Operation: 'stop'
        }
      }
    ]
  }
}

@description('Gives the Automation Account permission to stop/start the AKS cluster')
module aksAutomationRbac 'automationrunbook/aksRbac.bicep' = if (!empty(automationAccountScheduledStartStop)) {
  name: '${deployment().name}-automationrbac'
  params: {
    aksName: aks.name
    principalId: !empty(automationAccountScheduledStartStop) ? aksStartstop.outputs.automationAccountPrincipalId : ''
  }
}
