using '../main.bicep'

// Development Environment - AKS System Node Pool NSG
param resourceName = 'aks-system-nodes'
param location = 'East US'
param workspaceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-dev'
param workspaceResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-dev'
param workspaceRegion = 'East US'

// Rule configuration for AKS system nodes
param ruleInAllowGwManagement = false
param ruleInAllowAzureLoadBalancer = true
param ruleInDenyInternet = true
param ruleInAllowInternetHttp = false
param ruleInAllowInternetHttps = false
param ruleInAllowBastionHostComms = false
param ruleOutAllowBastionComms = false
param ruleInDenySsh = false

// Flow log configuration
param FlowLogStorageAccountId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-storage/providers/Microsoft.Storage/storageAccounts/stflowlogsdev'
param FlowLogTrafficAnalytics = true

// NSG diagnostic categories
param NsgDiagnosticCategories = [
  'NetworkSecurityGroupEvent'
  'NetworkSecurityGroupRuleCounter'
]
