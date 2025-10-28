using '../main.bicep'

// ============ BASIC CONFIGURATION ============
param resourceName = 'myaksdemo'
param location = 'East US 2'

// ============ AKS CLUSTER SETTINGS ============
param kubernetesVersion = '1.30'
param nodeVmSize = 'Standard_D4ds_v5'
param nodeCount = 3
param nodeCountMax = 10

// ============ SECURITY & IDENTITY ============
param enableAzureAD = true
param adminGroupObjectIds = [
  // Add your Azure AD admin group object IDs here
  // Example: '12345678-1234-1234-1234-123456789012'
]
param enablePrivateCluster = false
// param enableRBAC = true // Not declared in main.bicep
// param disableLocalAccounts = true // Not declared in main.bicep

// ============ INFRASTRUCTURE COMPONENTS ============
param acrSku = 'Standard'
param enableMonitoring = true
param enableBlobCSIDriver = true
param enableFileCSIDriver = true
param enableDiskCSIDriver = true
param enableWebAppRouting = false
param enableKEDA = false
param enableDapr = false
param enableDaprHA = false
param enableFluxGitOps = false
param enableAzurePolicy = true
param azurePolicyInitiative = 'Baseline'
// param enableWorkloadIdentity = true // Not declared in main.bicep
// param enableOidcIssuerProfile = true // Not declared in main.bicep
// param autoUpgradeProfileUpgradeChannel = 'stable' // Not declared in main.bicep
// param skuTier = 'Standard' // Not declared in main.bicep

// ============ OPTIONAL COMPONENTS ============
param enableKeyVault = false
param enableDnsZone = false
param dnsZoneName = '' // e.g., 'mycompany.com'
param enableFirewall = false
param firewallSku = 'Standard'
param enableApplicationGateway = false
param applicationGatewaySku = 'WAF_v2'
// The above parameters are already declared below or duplicated, removing duplicates

// ============ ADDITIONAL ENTERPRISE COMPONENTS ============
param enableBastion = false
param enableNatGateway = false
param natGatewayPublicIps = 2
param natGatewayIdleTimeoutMins = 30
param enableEventGrid = false
param enableAutomation = false
param automationStartHour = 8
param automationStopHour = 19
param automationFrequency = 'Weekday'
param enablePrivateEndpoints = false
param enableNetworkSecurityGroups = false
param enableSysLogCollection = false

// ============ NETWORKING CONFIGURATION ============
// Customize these CIDR ranges for your environment
param vnetAddressPrefix = '10.240.0.0/16'
param aksSubnetPrefix = '10.240.0.0/22'
param appGwSubnetPrefix = '10.240.5.0/24'
param firewallSubnetPrefix = '10.240.50.0/24'
param privateEndpointSubnetPrefix = '10.240.4.192/26'
param bastionSubnetPrefix = '10.240.4.128/26'
param baseTime = '2025-10-28T00:00:00Z' // Example value, update as needed

/*
DEPLOYMENT NOTES:
- This parameter file configures a comprehensive AKS environment using Azure Verified Modules
- All components from original template are now available as optional parameters

CORE OPTIONAL COMPONENTS:
- DNS Zone: Set enableDnsZone=true and provide dnsZoneName (e.g., 'mycompany.com')
- Key Vault: Set enableKeyVault=true for secure configuration storage
- Azure Firewall: Set enableFirewall=true for network security and egress control
- Application Gateway: Set enableApplicationGateway=true for WAF-enabled load balancing
- Private Cluster: Set enablePrivateCluster=true for enhanced security (production recommended)

ADDITIONAL ENTERPRISE COMPONENTS:
- Azure Bastion: Set enableBastion=true for secure VM access without public IPs
- NAT Gateway: Set enableNatGateway=true for predictable outbound IP addresses
  * Configure natGatewayPublicIps (1-16) for redundancy and capacity
  * Adjust natGatewayIdleTimeoutMins (4-120) for connection timeout behavior
- Event Grid: Set enableEventGrid=true for AKS event monitoring and automation
- Azure Automation: Set enableAutomation=true for scheduled AKS start/stop (cost optimization)
- Private Endpoints: Set enablePrivateEndpoints=true for network isolation of ACR/KeyVault
- Network Security Groups: Set enableNetworkSecurityGroups=true for subnet-level protection
- SysLog Collection: Set enableSysLogCollection=true for advanced monitoring

PRODUCTION RECOMMENDATIONS:
- enablePrivateCluster=true
- enableKeyVault=true
- enableFirewall=true for controlled egress
- enableApplicationGateway=true for public-facing applications
- enablePrivateEndpoints=true for enterprise security
- enableNetworkSecurityGroups=true for defense in depth
- enableAutomation=true for cost optimization

EXAMPLE FULL ENTERPRISE DEPLOYMENT:
Set all enable* parameters to true for complete enterprise-grade infrastructure
with maximum security, monitoring, and automation capabilities.
*/

// Optional advanced/enterprise features
param enableCustomUserNodePool = false
param customUserNodePoolName = 'userpool'
param enableAksRbacRole = false
param aksAdminPrincipalId = ''
param enableByoSubnetRbac = false
param byoAKSSubnetId = ''
param byoAKSPodSubnetId = ''
param byoSubnetPrincipalId = ''
param enableFastAlertingRole = false
param fastAlertingLawName = ''
param enableTelemetry = true
