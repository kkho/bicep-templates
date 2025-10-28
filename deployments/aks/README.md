# Enterprise AKS Infrastructure - Azure Verified Modules

A comprehensive Azure Kubernetes Service (AKS) infrastructure template using Microsoft's Azure Verified Modules (AVM) for production-grade Kubernetes deployments.

## Architecture Overview

This template creates a complete AKS infrastructure with enterprise security, networking, and monitoring capabilities:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Resource Group                              │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │   Virtual       │ │   AKS Cluster   │ │  Log Analytics  │    │
│ │   Network       │ │                 │ │   Workspace     │    │
│ │                 │ │ • Azure CNI     │ │                 │    │
│ │ • AKS Subnet    │ │ • RBAC/Azure AD │ │ • Container     │    │
│ │ • AppGW Subnet  │ │ • Auto-scaling  │ │   Insights      │    │
│ │ • Firewall      │ │ • Workload ID   │ │ • SysLog        │    │
│ │ • Bastion       │ │                 │ │   Collection    │    │
│ │ • Private EP    │ └─────────────────┘ └─────────────────┘    │
│ └─────────────────┘                                             │
│                                                                 │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │ Container       │ │   Key Vault     │ │ Azure Firewall  │    │
│ │ Registry (ACR)  │ │                 │ │                 │    │
│ │                 │ │ • Network       │ │ • Network       │    │
│ │ • Premium       │ │   Isolation     │ │   Security      │    │
│ │ • Private EP    │ │ • RBAC          │ │ • Egress Control│    │
│ │ • Zone Redundant│ │ • Soft Delete   │ │ • Threat Intel  │    │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘    │
│                                                                 │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │ Application     │ │ Azure Bastion   │ │  NAT Gateway    │    │
│ │ Gateway         │ │                 │ │                 │    │
│ │                 │ │ • Secure RDP/   │ │ • Predictable   │    │
│ │ • WAF v2        │ │   SSH Access    │ │   Outbound IPs  │    │
│ │ • Auto-scaling  │ │ • No Public IPs │ │ • Multiple IPs  │    │
│ │ • SSL/TLS       │ │   on VMs        │ │ • Zone Resilient│    │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘    │
│                                                                 │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │ Event Grid      │ │ Azure Automation│ │ Network         │    │
│ │                 │ │                 │ │ Security Groups │    │
│ │ • AKS Events    │ │ • Scheduled     │ │                 │    │
│ │ • Automation    │ │   Start/Stop    │ │ • Subnet        │    │
│ │ • Monitoring    │ │ • Cost Savings  │ │   Protection    │    │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### **Security First**

- **Azure AD Integration**: Native Azure RBAC for Kubernetes
- **Private Endpoints**: Network isolation for ACR and Key Vault
- **Azure Bastion**: Secure VM access without public IPs
- **Key Vault**: Secure secrets and certificate management
- **Network Security Groups**: Subnet-level traffic protection
- **Azure Firewall**: Advanced threat protection and egress control

### **Advanced Networking**

- **Azure CNI**: Enhanced pod networking
- **NAT Gateway**: Predictable outbound IP addresses (configurable 1-16 IPs)
- **Application Gateway**: Layer 7 load balancing with WAF protection
- **Private Cluster**: API server endpoint isolation options
- **Custom VNet**: Segmented subnets for different workloads

### **Enterprise Monitoring**

- **Container Insights**: Deep container and cluster observability
- **Log Analytics**: Centralized logging and analytics
- **SysLog Collection**: Linux system log aggregation
- **Event Grid**: AKS cluster event automation
- **Azure Monitor**: Custom metrics and alerting

### **Cost Optimization**

- **Azure Automation**: Scheduled cluster start/stop (weekday/daily)
- **Auto-scaling**: Horizontal and vertical pod autoscaling
- **Spot Instances**: Cost-effective burst capacity options
- **Zone-Redundant Storage**: Optimal cost vs. availability balance

## Quick Start

### Option 1: Development Environment

```bash
# Clone the repository
git clone <your-repo-url>
cd bicep-templates/aks

# Deploy with development configuration
az deployment group create \
  --resource-group myaks-dev-rg \
  --template-file main.bicep \
  --parameters @examples/complete-dev.bicepparam
```

### Option 2: Production Environment

```bash
# Deploy with enterprise production configuration
az deployment group create \
  --resource-group myaks-prod-rg \
  --template-file main.bicep \
  --parameters @examples/enterprise-production.bicepparam
```

### Option 3: Custom Configuration

Create your own parameter file:

```bicep
// my-config.bicepparam
using 'main.bicep'

param resourceName = 'mycompany-aks'
param location = 'East US 2'
param enableFirewall = true
param enableBastion = true
param enablePrivateCluster = true
param enableAutomation = true
```

## Template Comparison

| Component            | main.bicep (Original) | aks/main.bicep (AVM)   | Enhancement             |
| -------------------- | --------------------- | ---------------------- | ----------------------- |
| **Lines of Code**    | 1,600+                | ~950                   | ✅ 40% reduction        |
| **Modules Used**     | Custom modules        | Azure Verified Modules | ✅ Microsoft-maintained |
| **Security Updates** | Manual                | Automatic via AVM      | ✅ Always current       |
| **Best Practices**   | Template-specific     | Built into AVM         | ✅ Industry standard    |
| **Maintenance**      | High effort           | Low effort             | ✅ Simplified           |
| **Feature Parity**   | 100%                  | 100%+                  | ✅ Enhanced             |

## Configuration Options

### Core Parameters

| Parameter           | Description            | Default                 | Required |
| ------------------- | ---------------------- | ----------------------- | -------- |
| `resourceName`      | Resource naming prefix | -                       | ✅       |
| `location`          | Azure region           | Resource Group location | ❌       |
| `kubernetesVersion` | K8s version            | `'1.30'`                | ❌       |
| `nodeVmSize`        | VM SKU for nodes       | `'Standard_D4ds_v5'`    | ❌       |
| `nodeCount`         | Initial node count     | `3`                     | ❌       |
| `nodeCountMax`      | Max nodes for scaling  | `10`                    | ❌       |

### Security & Identity

| Parameter              | Description          | Default |
| ---------------------- | -------------------- | ------- |
| `enableAzureAD`        | Azure AD integration | `true`  |
| `adminGroupObjectIds`  | Admin group IDs      | `[]`    |
| `enablePrivateCluster` | Private API server   | `false` |
| `enableKeyVault`       | Key Vault creation   | `false` |

### Optional Components

| Parameter                     | Description              | Default | Production Rec. |
| ----------------------------- | ------------------------ | ------- | --------------- |
| `enableFirewall`              | Azure Firewall           | `false` | ✅ `true`       |
| `enableApplicationGateway`    | App Gateway + WAF        | `false` | ✅ `true`       |
| `enableBastion`               | Secure VM access         | `false` | ✅ `true`       |
| `enableNatGateway`            | Predictable outbound IPs | `false` | ✅ `true`       |
| `enablePrivateEndpoints`      | Network isolation        | `false` | ✅ `true`       |
| `enableNetworkSecurityGroups` | Subnet protection        | `false` | ✅ `true`       |
| `enableAutomation`            | Cost optimization        | `false` | ✅ `true`       |
| `enableEventGrid`             | Event monitoring         | `false` | ❌ `false`      |
| `enableSysLogCollection`      | Advanced logging         | `false` | ❌ `false`      |

### NAT Gateway Configuration

| Parameter                   | Description          | Default | Range |
| --------------------------- | -------------------- | ------- | ----- |
| `natGatewayPublicIps`       | Number of public IPs | `2`     | 1-16  |
| `natGatewayIdleTimeoutMins` | Connection timeout   | `30`    | 4-120 |

### Automation Scheduling

| Parameter             | Description        | Default     | Options              |
| --------------------- | ------------------ | ----------- | -------------------- |
| `automationStartHour` | Cluster start time | `8` (8 AM)  | 0-23                 |
| `automationStopHour`  | Cluster stop time  | `19` (7 PM) | 0-23                 |
| `automationFrequency` | Schedule pattern   | `'Weekday'` | `'Weekday'`, `'Day'` |

## Deployment Examples

### Minimal Development Setup

```bicep
param resourceName = 'dev-aks'
param location = 'West Europe'
param enableMonitoring = true
param acrSku = 'Basic'
```

**Estimated Cost**: ~$200-400/month

### Standard Enterprise Setup

```bicep
param resourceName = 'prod-aks'
param location = 'East US 2'
param enableFirewall = true
param enableApplicationGateway = true
param enablePrivateCluster = true
param enableKeyVault = true
param enableBastion = true
param enableNatGateway = true
param enablePrivateEndpoints = true
param enableNetworkSecurityGroups = true
param acrSku = 'Premium'
```

**Estimated Cost**: ~$800-1500/month

### Cost-Optimized with Automation

```bicep
param resourceName = 'costopt-aks'
param enableAutomation = true
param automationStartHour = 8        // Start 8 AM
param automationStopHour = 18        // Stop 6 PM
param automationFrequency = 'Weekday' // Weekdays only
param nodeCountMax = 5               // Limit scaling
```

**Cost Savings**: ~40-60% reduction for dev/test environments

## Advanced Configuration

### Custom Networking

```bicep
param vnetAddressPrefix = '10.100.0.0/16'
param aksSubnetPrefix = '10.100.0.0/20'     // Larger for more pods
param appGwSubnetPrefix = '10.100.16.0/24'
param firewallSubnetPrefix = '10.100.17.0/24'
param bastionSubnetPrefix = '10.100.18.0/26'
```

### High Availability NAT Gateway

```bicep
param enableNatGateway = true
param natGatewayPublicIps = 4        // 4 IPs for redundancy
param natGatewayIdleTimeoutMins = 60 // Extended timeout
```

### Enterprise Automation

```bicep
param enableAutomation = true
param automationStartHour = 6        // Early start
param automationStopHour = 22        // Late stop
param automationFrequency = 'Day'    // 7 days/week
```

## Monitoring & Observability

### Included Monitoring Components

- **Container Insights**: Pod, node, and cluster metrics
- **Log Analytics Workspace**: Centralized logging
- **Azure Monitor**: Custom metrics and alerts
- **SysLog Collection**: Linux system logs (optional)
- **Event Grid**: Cluster lifecycle events (optional)

### Log Categories Available

- `cluster-autoscaler`: Scaling events
- `kube-controller-manager`: Control plane logs
- `kube-audit-admin`: Admin API calls
- `guard`: Authentication events

### Custom Queries

```kusto
// Top resource-consuming pods
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize avg(CpuUsageNanoseconds) by Name
| top 10 by avg_CpuUsageNanoseconds

// Node health status
KubeNodeInventory
| where TimeGenerated > ago(5m)
| summarize by Computer, Status
```

## Security Best Practices

### Network Security

**Enabled by Default:**

- Private cluster option
- Network Security Groups
- Service endpoints
- Azure CNI networking

**Available Components:**

- Azure Firewall with threat intelligence
- Private endpoints for services
- Azure Bastion for secure access
- NAT Gateway for predictable egress

### Identity & Access

**Azure AD Integration:**

- Native Kubernetes RBAC
- Azure role assignments
- Workload Identity support
- Managed Identity for pods

  **Key Management:**

- Azure Key Vault integration
- CSI secret store driver
- Automatic secret rotation
- Network-isolated access

## Troubleshooting

### Common Deployment Issues

**Error**: `Private cluster requires managed identity`

```bash
# Solution: Ensure you have appropriate permissions
az role assignment create \
  --assignee <user-id> \
  --role "Managed Identity Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>"
```

**Error**: `Subnet address space conflicts`

```bicep
// Solution: Adjust CIDR ranges in parameters
param vnetAddressPrefix = '10.240.0.0/16'  // Ensure no overlap
param aksSubnetPrefix = '10.240.0.0/22'    // with existing networks
```

**Error**: `NAT Gateway quota exceeded`

```bash
# Solution: Request quota increase or reduce public IP count
param natGatewayPublicIps = 2  // Reduce from default
```

### Validation Commands

```bash
# Check AKS cluster status
az aks show --resource-group <rg> --name <cluster> --query "powerState"

# Verify node health
kubectl get nodes -o wide

# Check pod status
kubectl get pods --all-namespaces

# Validate networking
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default
```

## Updates & Maintenance

### Updating the Template

This template uses Azure Verified Modules, which are automatically updated:

- **Security patches**: Applied automatically
- **Feature updates**: Available through AVM version updates
- **Best practices**: Continuously evolved by vendor

### Manual Updates

```bash
# Update to latest AVM versions (when needed)
az bicep upgrade

# Validate template before deployment
az deployment group validate \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @examples/your-config.bicepparam
```

## 📚 Additional Resources

- [Azure Verified Modules](https://aka.ms/avm)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/)
- [Azure CNI Networking](https://docs.microsoft.com/azure/aks/concepts-network)
- [Azure AD Integration](https://docs.microsoft.com/azure/aks/managed-aad)

## Contributing

This template follows the Azure Verified Modules methodology. Contributions should:

1. Maintain AVM module usage
2. Follow security best practices
3. Include parameter validation
4. Update documentation
5. Add appropriate examples

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This template represents a production-ready, enterprise-grade AKS deployment using recommended Azure Verified Modules approach. It provides the same functionality as the original complex template while being significantly easier to maintain and automatically staying current with security updates.
