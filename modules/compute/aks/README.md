# Azure Kubernetes Service (AKS) Module

**Complexity:** Intermediate to Advanced  
**Estimated Cost:** $$$ (High - varies significantly by configuration)  
**Azure Services:** Azure Kubernetes Service, Azure Container Registry, Log Analytics, Azure Monitor

## Overview

This module creates a production-ready Azure Kubernetes Service (AKS) cluster with comprehensive security, monitoring, and networking configurations. Supports both regular AKS and AKS on Azure Arc scenarios.

## Features

- ✅ Multiple node pools (system and user)
- ✅ Auto-scaling with cluster autoscaler
- ✅ Azure CNI or Kubenet networking
- ✅ Azure AD integration and RBAC
- ✅ Private cluster support
- ✅ Azure Monitor for containers integration
- ✅ Managed identity support
- ✅ Network policies (Azure or Calico)
- ✅ Pod security standards
- ✅ Workload identity support
- ✅ Azure Key Vault secrets provider
- ✅ Application Gateway Ingress Controller (AGIC)

## Architecture Patterns Supported

### Standard AKS Cluster

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure CNI     │    │  System Nodes   │    │   User Nodes    │
│   Networking    │────│  (3 nodes)      │────│  (auto-scale)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Log Analytics  │
                    │   Monitoring    │
                    └─────────────────┘
```

### Private AKS Cluster

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Private Subnet │    │   AKS Cluster   │    │ Private Endpoint│
│     (Nodes)     │────│  (Private API)  │────│   (API Server)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Azure Bastion │
                    │  (Management)   │
                    └─────────────────┘
```

## Parameters

### Required Parameters

| Parameter     | Type   | Description                                                         |
| ------------- | ------ | ------------------------------------------------------------------- |
| `clusterName` | string | Name of the AKS cluster (3-63 characters, alphanumeric and hyphens) |
| `location`    | string | Azure region for deployment                                         |

### Core Configuration

| Parameter           | Type   | Default                                                   | Description                                       |
| ------------------- | ------ | --------------------------------------------------------- | ------------------------------------------------- |
| `kubernetesVersion` | string | `null`                                                    | Kubernetes version (uses latest if not specified) |
| `dnsPrefix`         | string | `clusterName`                                             | DNS prefix for the cluster                        |
| `nodeResourceGroup` | string | `'MC_${resourceGroup().name}_${clusterName}_${location}'` | Resource group for cluster nodes                  |

### Node Pool Configuration

| Parameter              | Type   | Default             | Description                    |
| ---------------------- | ------ | ------------------- | ------------------------------ |
| `systemNodePoolConfig` | object | See defaults        | System node pool configuration |
| `userNodePools`        | array  | `[]`                | Additional user node pools     |
| `enableAutoScaling`    | bool   | `true`              | Enable cluster autoscaler      |
| `minNodeCount`         | int    | `1`                 | Minimum nodes when autoscaling |
| `maxNodeCount`         | int    | `10`                | Maximum nodes when autoscaling |
| `nodeVmSize`           | string | `'Standard_D2s_v3'` | VM size for nodes              |
| `osDiskSizeGB`         | int    | `30`                | OS disk size in GB             |
| `osDiskType`           | string | `'Managed'`         | OS disk type                   |

### Networking Configuration

| Parameter              | Type   | Default         | Description                     |
| ---------------------- | ------ | --------------- | ------------------------------- |
| `networkPlugin`        | string | `'azure'`       | Network plugin (azure, kubenet) |
| `networkPolicy`        | string | `'azure'`       | Network policy (azure, calico)  |
| `serviceCidr`          | string | `'10.0.0.0/16'` | Service CIDR range              |
| `dnsServiceIP`         | string | `'10.0.0.10'`   | DNS service IP                  |
| `subnetId`             | string | `''`            | Existing subnet resource ID     |
| `enablePrivateCluster` | bool   | `false`         | Enable private cluster          |
| `privateDNSZoneId`     | string | `''`            | Private DNS zone resource ID    |

### Security & Identity

| Parameter                       | Type  | Default | Description                             |
| ------------------------------- | ----- | ------- | --------------------------------------- |
| `enableRBAC`                    | bool  | `true`  | Enable Kubernetes RBAC                  |
| `enableAzureRBAC`               | bool  | `true`  | Enable Azure RBAC for Kubernetes        |
| `aadProfileManaged`             | bool  | `true`  | Use Azure AD managed integration        |
| `aadProfileAdminGroupObjectIDs` | array | `[]`    | Azure AD admin group object IDs         |
| `enableWorkloadIdentity`        | bool  | `true`  | Enable workload identity                |
| `enableOidcIssuer`              | bool  | `true`  | Enable OIDC issuer                      |
| `enableSecretStoreCSI`          | bool  | `true`  | Enable Azure Key Vault secrets provider |

### Monitoring & Logging

| Parameter                 | Type   | Default | Description                         |
| ------------------------- | ------ | ------- | ----------------------------------- |
| `enableMonitoring`        | bool   | `true`  | Enable Azure Monitor for containers |
| `logAnalyticsWorkspaceId` | string | `''`    | Log Analytics workspace resource ID |
| `enableContainerInsights` | bool   | `true`  | Enable container insights           |

### Add-ons & Extensions

| Parameter                         | Type   | Default | Description                       |
| --------------------------------- | ------ | ------- | --------------------------------- |
| `enableIngressApplicationGateway` | bool   | `false` | Enable AGIC add-on                |
| `applicationGatewayId`            | string | `''`    | Application Gateway resource ID   |
| `enableAzurePolicy`               | bool   | `true`  | Enable Azure Policy add-on        |
| `enableKeyVaultSecretsProvider`   | bool   | `true`  | Enable Key Vault secrets provider |

## Outputs

| Output                      | Type   | Description                             |
| --------------------------- | ------ | --------------------------------------- |
| `clusterName`               | string | Name of the AKS cluster                 |
| `clusterResourceId`         | string | Resource ID of the AKS cluster          |
| `clusterFQDN`               | string | FQDN of the cluster API server          |
| `nodeResourceGroup`         | string | Resource group containing cluster nodes |
| `kubeletIdentity`           | object | Kubelet managed identity details        |
| `oidcIssuerUrl`             | string | OIDC issuer URL (if enabled)            |
| `clusterIdentity`           | object | Cluster managed identity details        |
| `ingressApplicationGateway` | object | AGIC configuration (if enabled)         |

## Usage Examples

### Basic AKS Cluster

```bicep
module aks 'modules/compute/aks/main.bicep' = {
  name: 'basicAksCluster'
  params: {
    clusterName: 'my-aks-cluster'
    location: 'eastus2'
    nodeVmSize: 'Standard_D2s_v3'
    minNodeCount: 2
    maxNodeCount: 10
  }
}
```

### Private AKS Cluster with Custom Networking

```bicep
module aks 'modules/compute/aks/main.bicep' = {
  name: 'privateAksCluster'
  params: {
    clusterName: 'private-aks-cluster'
    location: 'eastus2'
    enablePrivateCluster: true
    subnetId: '/subscriptions/.../subnets/aks-subnet'
    networkPlugin: 'azure'
    serviceCidr: '172.16.0.0/16'
    dnsServiceIP: '172.16.0.10'
    aadProfileAdminGroupObjectIDs: [
      '12345678-1234-1234-1234-123456789012'
    ]
  }
}
```

### Production AKS with Multiple Node Pools

```bicep
module aks 'modules/compute/aks/main.bicep' = {
  name: 'productionAksCluster'
  params: {
    clusterName: 'prod-aks-cluster'
    location: 'eastus2'
    kubernetesVersion: '1.28.3'
    systemNodePoolConfig: {
      vmSize: 'Standard_D4s_v3'
      count: 3
      minCount: 3
      maxCount: 6
      enableAutoScaling: true
      osDiskSizeGB: 50
      maxPods: 30
    }
    userNodePools: [
      {
        name: 'workernodes'
        vmSize: 'Standard_D8s_v3'
        count: 3
        minCount: 3
        maxCount: 20
        enableAutoScaling: true
        nodeLabels: {
          'workload-type': 'general'
        }
        nodeTaints: []
      }
      {
        name: 'gpunodes'
        vmSize: 'Standard_NC6s_v3'
        count: 0
        minCount: 0
        maxCount: 5
        enableAutoScaling: true
        nodeLabels: {
          'workload-type': 'gpu'
        }
        nodeTaints: [
          'nvidia.com/gpu=true:NoSchedule'
        ]
      }
    ]
    enableMonitoring: true
    enableAzurePolicy: true
    enableWorkloadIdentity: true
  }
}
```

## Cost Estimation

### Node Pool Costs (per month)

| VM Size         | vCPUs | RAM  | Approx. Cost/Node |
| --------------- | ----- | ---- | ----------------- |
| Standard_B2s    | 2     | 4GB  | $30-40            |
| Standard_D2s_v3 | 2     | 8GB  | $70-80            |
| Standard_D4s_v3 | 4     | 16GB | $140-160          |
| Standard_D8s_v3 | 8     | 32GB | $280-320          |

### Additional Costs

- **Log Analytics**: $2-5 per GB ingested
- **Azure Monitor**: $0.25 per million API calls
- **Load Balancer**: $18-25/month + data processing
- **Public IP**: $3-4/month per IP
- **Storage**: $0.10-0.20 per GB/month

### Typical Scenarios

- **Development**: 2-3 nodes × Standard_B2s = $60-120/month
- **Production**: 6-10 nodes × Standard_D4s_v3 = $840-1,600/month
- **Enterprise**: 10+ nodes + GPU nodes = $2,000+/month

## Prerequisites

1. **Azure Subscription** with sufficient quota
2. **Resource Group** must exist
3. **Virtual Network and Subnet** (for custom networking)
4. **Log Analytics Workspace** (for monitoring)
5. **RBAC Permissions**:
   - `Azure Kubernetes Service Cluster Admin Role`
   - `Network Contributor` (for networking resources)
   - `Managed Identity Operator` (for managed identities)

## Post-Deployment Configuration

### Connect to Cluster

```bash
# Get credentials
az aks get-credentials --resource-group myResourceGroup --name myAksCluster

# Verify connection
kubectl get nodes
```

### Install Essential Tools

```bash
# Install ingress controller (if not using AGIC)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# Install cert-manager for TLS
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

## Security Best Practices

1. **Enable Azure AD integration** and RBAC
2. **Use private clusters** for production workloads
3. **Implement network policies** to control pod communication
4. **Enable Azure Policy** for governance
5. **Use workload identity** instead of service principals
6. **Enable audit logging** and monitoring
7. **Regularly update** Kubernetes and node images
8. **Implement pod security standards**
9. **Use Azure Key Vault** for secrets management
10. **Enable vulnerability scanning** for container images

## Troubleshooting

### Common Issues

| Issue                   | Solution                                      |
| ----------------------- | --------------------------------------------- |
| Insufficient quota      | Request quota increase in Azure portal        |
| Network connectivity    | Check NSG rules and route tables              |
| Authentication failures | Verify Azure AD integration and RBAC settings |
| Pod scheduling failures | Check node capacity and resource requests     |

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check resource usage
kubectl top nodes
kubectl top pods

# View logs
kubectl logs -n kube-system -l k8s-app=azure-cni-networkmonitor
```

## Related Modules

- [Azure Container Registry (ACR)](../../containers/acr/) - Store container images
- [Application Gateway](../../networking/application-gateway/) - Ingress controller
- [Log Analytics](../../monitoring/log-analytics/) - Monitoring and logging
- [Key Vault](../../security/keyvault/) - Secrets management
- [Virtual Network](../../networking/vnet/) - Custom networking

## References

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure CNI Networking](https://docs.microsoft.com/azure/aks/configure-azure-cni)
- [AKS Security Best Practices](https://docs.microsoft.com/azure/aks/security-best-practices)
