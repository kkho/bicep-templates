using '../main.bicep'

// Production Environment - Bastion Host NSG
param resourceName = 'bastion-host'
param location = 'East US'
param workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceRegion = 'East US'

// Rule configuration for Azure Bastion
param ruleInAllowGwManagement = true
param ruleInGwManagementPort = '443'
param ruleInAllowAzureLoadBalancer = true
param ruleInDenyInternet = false
param ruleInAllowInternetHttp = false
param ruleInAllowInternetHttps = true
param ruleInAllowBastionHostComms = true
param ruleOutAllowBastionComms = true
param ruleInDenySsh = false

// Flow log configuration
param FlowLogStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/stflowlogsprod'
param FlowLogTrafficAnalytics = true

// NSG diagnostic categories
param NsgDiagnosticCategories = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]
