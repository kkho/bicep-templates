using '../main.bicep'

// Staging environment parameters
param acrName = 'contosoacrstaging'
param aksName = 'contoso-aks-staging'
param registries_sku = 'Standard'
param location = 'eastus2'
param aksResourceGroup = 'rg-aks-staging'

// Diagnostics settings
param enableDiagnostics = true
param logAnalyticsWorkspaceId = '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring-staging/providers/Microsoft.OperationalInsights/workspaces/logs-staging'
param diagnosticLogRetentionInDays = 60

// Security settings (medium for staging)
param enableACRTrustPolicy = false // Not available in Standard SKU
param privateLinks = false // Simplified networking for staging
param acrUntaggedRetentionPolicyEnabled = true
param acrUntaggedRetentionPolicy = 14 // Medium retention for staging
