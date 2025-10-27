using '../main.bicep'

// Production environment parameters
param acrName = 'contosoacrprod'
param aksName = 'contoso-aks-prod'
param registries_sku = 'Premium'
param location = 'eastus2'
param aksResourceGroup = 'rg-aks-prod'
param availabilityZones = ['1', '2', '3']

// Diagnostics settings
param enableDiagnostics = true
param logAnalyticsWorkspaceId = '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/logs-prod'
param diagnosticLogRetentionInDays = 90

// Security settings (maximum for production)
param enableACRTrustPolicy = true // Premium feature
param privateLinks = true // Enhanced security
param acrUntaggedRetentionPolicyEnabled = true
param acrUntaggedRetentionPolicy = 30 // Longer retention for prod
