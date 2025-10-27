using '../main.bicep'

// Production Environment - Web Server NSG
param resourceName = 'web-servers'
param location = 'East US'
param workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-prod'
param workspaceRegion = 'East US'

// Rule configuration for web servers
param ruleInAllowGwManagement = false
param ruleInAllowAzureLoadBalancer = true
param ruleInDenyInternet = true // Deny all internet except HTTP/HTTPS
param ruleInAllowInternetHttp = true
param ruleInAllowInternetHttps = true
param ruleInAllowBastionHostComms = false
param ruleOutAllowBastionComms = false
param ruleInDenySsh = true // Deny SSH from internet

// Flow log configuration
param FlowLogStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/stflowlogsprod'
param FlowLogTrafficAnalytics = true

// NSG diagnostic categories
param NsgDiagnosticCategories = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]
