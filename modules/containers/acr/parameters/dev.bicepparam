using '../main.bicep'

// Development environment parameters
param acrName = 'contosoacrdev'
param aksName = 'contoso-aks-dev'
param registries_sku = 'Basic'
param location = 'eastus2'
param aksResourceGroup = 'rg-aks-dev'

// Diagnostics settings
param enableDiagnostics = true
param logAnalyticsWorkspaceId = '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring-dev/providers/Microsoft.OperationalInsights/workspaces/logs-dev'
param diagnosticLogRetentionInDays = 30

// Security settings (minimal for dev)
param enableACRTrustPolicy = false
param privateLinks = false
param acrUntaggedRetentionPolicyEnabled = true
param acrUntaggedRetentionPolicy = 7 // Short retention for dev
