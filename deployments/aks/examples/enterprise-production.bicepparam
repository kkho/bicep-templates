using '../main.bicep'

// ============ BASIC CONFIGURATION ============
param resourceName = 'prodaks'
param location = 'East US 2'

// ============ AKS CLUSTER SETTINGS ============
param kubernetesVersion = '1.30'
param nodeVmSize = 'Standard_D8ds_v5' // Larger VMs for production
param nodeCount = 5 // More nodes for production
param nodeCountMax = 20 // Higher scaling limit

// ============ SECURITY & IDENTITY ============
param enableAzureAD = true
param adminGroupObjectIds = [
  // Add your Azure AD admin group object IDs here
  // Example: '12345678-1234-1234-1234-123456789012'
]
param enablePrivateCluster = true // PRODUCTION: Private API server

// ============ INFRASTRUCTURE COMPONENTS ============
param acrSku = 'Premium' // Premium for production features
param enableMonitoring = true

// ============ CORE OPTIONAL COMPONENTS - ALL ENABLED ============
param enableKeyVault = true
param enableDnsZone = true
param dnsZoneName = 'mycompany.com' // Replace with your domain
param enableFirewall = true
param firewallSku = 'Premium' // Premium for advanced threat protection
param enableApplicationGateway = true
param applicationGatewaySku = 'WAF_v2'

// ============ ENTERPRISE COMPONENTS - ALL ENABLED ============
param enableBastion = true
param enableNatGateway = true
param natGatewayPublicIps = 3 // More IPs for production redundancy
param natGatewayIdleTimeoutMins = 30
param enableEventGrid = true
param enableAutomation = true
param automationStartHour = 7 // Start early for business hours
param automationStopHour = 20 // Stop late for extended hours
param automationFrequency = 'Weekday' // Only weekdays for office environment
param enablePrivateEndpoints = true
param enableNetworkSecurityGroups = true
param enableSysLogCollection = true

// ============ PRODUCTION NETWORKING CONFIGURATION ============
// Production-grade CIDR allocation
param vnetAddressPrefix = '10.100.0.0/16' // Larger range for production
param aksSubnetPrefix = '10.100.0.0/20' // Larger AKS subnet for more pods
param appGwSubnetPrefix = '10.100.16.0/24'
param firewallSubnetPrefix = '10.100.17.0/24'
param privateEndpointSubnetPrefix = '10.100.18.0/24'
param bastionSubnetPrefix = '10.100.19.0/26'

/*
ENTERPRISE PRODUCTION DEPLOYMENT
==================================

This parameter file configures a complete enterprise-grade AKS environment with:

✅ SECURITY FEATURES:
- Private AKS cluster (API server not publicly accessible)
- Azure Firewall with Premium threat protection
- Private endpoints for ACR and Key Vault network isolation
- Network Security Groups on all subnets
- Azure Bastion for secure VM access
- Azure AD integration with RBAC

✅ NETWORKING FEATURES:
- NAT Gateway with multiple public IPs for redundancy and predictable outbound addressing
- Application Gateway with WAF v2 for protection against web vulnerabilities
- Segmented subnets for different services
- Production-grade CIDR allocation

✅ MONITORING & AUTOMATION:
- Log Analytics workspace with SysLog collection
- Event Grid for AKS event monitoring
- Azure Automation for scheduled start/stop (cost optimization)
- Premium monitoring capabilities

✅ HIGH AVAILABILITY:
- Larger VM sizes for production workloads
- Higher node count and scaling limits
- Premium ACR with geo-replication capabilities
- Multi-zone deployment support

DEPLOYMENT COST CONSIDERATIONS:
- Premium Firewall: ~$2,000/month
- Application Gateway WAF v2: ~$300/month
- Azure Bastion: ~$150/month
- NAT Gateway: ~$50/month + data processing
- Premium ACR: Additional storage and bandwidth costs
- AKS nodes: Variable based on VM size and count

TOTAL ESTIMATED MONTHLY COST: ~$3,000-5,000+ depending on usage

This configuration provides enterprise-grade security, monitoring, and automation
suitable for production workloads requiring maximum protection and operational efficiency.
*/

// Advanced AKS features and add-ons (ensure full parity with main.bicep)
param enableBlobCSIDriver = true
param enableFileCSIDriver = true
param enableDiskCSIDriver = true
param enableWebAppRouting = true
param enableKEDA = true
param enableDapr = true
param enableDaprHA = true
param enableFluxGitOps = true
param enableAzurePolicy = true
param azurePolicyInitiative = 'Baseline'
param enableCustomUserNodePool = true
param customUserNodePoolName = 'userpool-prod'
param enableAksRbacRole = true
param aksAdminPrincipalId = ''
param enableByoSubnetRbac = false
param byoAKSSubnetId = ''
param byoAKSPodSubnetId = ''
param byoSubnetPrincipalId = ''
param enableFastAlertingRole = true
param fastAlertingLawName = 'law-prodaks'
param enableTelemetry = true
