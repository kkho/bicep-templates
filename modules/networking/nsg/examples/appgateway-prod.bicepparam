using '../main.bicep'

// Production Environment - Application Gateway NSG
param resourceName = 'application-gateway'
param location = 'East US'
param workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceRegion = 'East US'

// Rule configuration for Application Gateway
param ruleInAllowGwManagement = true
param ruleInGwManagementPort = '443,65200-65535'
param ruleInAllowAzureLoadBalancer = true
param ruleInDenyInternet = false
param ruleInAllowInternetHttp = true
param ruleInAllowInternetHttps = true
param ruleInAllowBastionHostComms = false
param ruleOutAllowBastionComms = false
param ruleInDenySsh = true

// Flow log configuration
param FlowLogStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/stflowlogsprod'
param FlowLogTrafficAnalytics = true

// NSG diagnostic categories
param NsgDiagnosticCategories = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]
