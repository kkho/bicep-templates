# Azure Container Registry Module

**Complexity:** Intermediate
**Estimated Cost:** $$ (Medium)
**Azure Services:** Azure Container Registry, Private Endpoints, Network Security Groups

## Overview

This module creates a production-ready Azure Container Registry (ACR) with security best practices including private endpoints, vulnerability scanning, and role-based access control.

## Features

- ✅ Premium SKU with geo-replication support
- ✅ Private endpoint integration
- ✅ Vulnerability scanning enabled
- ✅ Content trust and signed images
- ✅ Network access rules
- ✅ Admin user disabled (RBAC only)

## Parameters

### Required Parameters

| Parameter | Type   | Description                                         |
| --------- | ------ | --------------------------------------------------- |
| `acrName` | string | Name of the Azure Container Registry                |
| `aksName` | string | Name of the AKS cluster that will use this registry |

### Configuration Parameters

| Parameter           | Type   | Default                  | Description                             |
| ------------------- | ------ | ------------------------ | --------------------------------------- |
| `registries_sku`    | string | 'Standard'               | Registry SKU (Basic, Standard, Premium) |
| `location`          | string | resourceGroup().location | Azure region                            |
| `aksResourceGroup`  | string | resourceGroup().name     | Resource group where AKS is deployed    |
| `availabilityZones` | array  | []                       | Availability zones (Premium SKU only)   |

### Security Parameters

| Parameter                           | Type | Default | Description                             |
| ----------------------------------- | ---- | ------- | --------------------------------------- |
| `enableACRTrustPolicy`              | bool | false   | Enable content trust (Premium SKU only) |
| `privateLinks`                      | bool | false   | Enable private endpoint                 |
| `acrUntaggedRetentionPolicyEnabled` | bool | false   | Enable cleanup of untagged manifests    |
| `acrUntaggedRetentionPolicy`        | int  | 30      | Days to retain untagged manifests       |

### Diagnostics Parameters

| Parameter                      | Type   | Default | Description                          |
| ------------------------------ | ------ | ------- | ------------------------------------ |
| `enableDiagnostics`            | bool   | true    | Enable diagnostic settings           |
| `logAnalyticsWorkspaceId`      | string | ''      | Log Analytics workspace resource ID  |
| `storageAccountId`             | string | ''      | Storage account resource ID for logs |
| `diagnosticLogRetentionInDays` | int    | 30      | Log retention period in days         |
| `enableMetrics`                | bool   | true    | Enable metrics collection            |
| `enableLogs`                   | bool   | true    | Enable logs collection               |

## Outputs

| Output                         | Type   | Description                     |
| ------------------------------ | ------ | ------------------------------- |
| `containerRegistryName`        | string | Name of the registry            |
| `containerRegistryId`          | string | Resource ID of the registry     |
| `containerRegistryLoginServer` | string | Registry login server URL       |
| `diagnosticsEnabled`           | bool   | Whether diagnostics are enabled |
| `acrDetails`                   | object | Complete ACR details object     |

## Usage Examples

### Basic Development Setup

```bicep
module acr 'modules/containers/acr/main.bicep' = {
  name: 'devAcrDeployment'
  params: {
    acrName: 'mycompanyacrdev'
    aksName: 'my-aks-dev'
    registries_sku: 'Basic'
    location: 'eastus2'
    enableDiagnostics: false
  }
}
```

### Production Setup with Diagnostics

```bicep
module acr 'modules/containers/acr/main.bicep' = {
  name: 'prodAcrDeployment'
  params: {
    acrName: 'mycompanyacrprod'
    aksName: 'my-aks-prod'
    registries_sku: 'Premium'
    location: 'eastus2'
    availabilityZones: ['1', '2', '3']
    enableACRTrustPolicy: true
    privateLinks: true
    enableDiagnostics: true
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}
```

### Using Parameter Files

```bash
# Deploy using environment-specific parameters
az deployment group create \
  --resource-group rg-containers-prod \
  --template-file modules/containers/acr/main.bicep \
  --parameters modules/containers/acr/parameters/prod.bicepparam
```

## Cost Estimation

- **Basic SKU**: ~$5-15/month + storage
- **Standard SKU**: ~$20-50/month + storage
- **Premium SKU**: ~$500+/month + storage + geo-replication

## Prerequisites

- Resource Group must exist
- Virtual Network and subnet (if using private endpoints)
- Appropriate RBAC permissions (Contributor or ACR-specific roles)

## Related Modules

- [AKS](../../../compute/aks/) - Kubernetes service that can pull from this registry
- [Private Endpoints](../../networking/private-endpoint/) - Network security
- [Key Vault](../../security/keyvault/) - Store registry credentials
