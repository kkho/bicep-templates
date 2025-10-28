# Azure Cloud Platform - Bicep Templates

A comprehensive collection of Azure Bicep templates for deploying enterprise-grade cloud infrastructure with full observability, security, and networking capabilities.

## Architecture Overview

This repository provides templates for deploying a complete Azure platform including:

- **Networking**: VNets, Subnets, NSGs, Application Gateway, Azure Firewall
- **Security**: Key Vault, Managed Identity, Private Endpoints, Azure Policy
- **DNS**: Private DNS Zones, Public DNS, DNS Resolvers
- **Containers**: Azure Container Registry, Azure Kubernetes Service
- **Monitoring**: Log Analytics, Application Insights, Azure Monitor
- **Observability**: OpenTelemetry, Prometheus, Grafana integration
- **Deployment**: Complete solution architectures

## Quick Start

### Prerequisites

- Azure CLI 2.40+ with Bicep extension
- Azure subscription with appropriate permissions
- PowerShell 7+ (for automation scripts)

### Installation

```bash
# Install Azure CLI and Bicep extension
az bicep install

# Or download directly from GitHub releases
# https://github.com/Azure/bicep/releases
```

### Test, Validate and Compile Bicep Templates

```bash
# Compile and validate
az bicep build --file main.bicep

# Lint only (check syntax without compiling)
az bicep lint --file main.bicep

# With output file
az bicep build --file main.bicep --outfile template.json

# Compile and watch for changes
az bicep build --file main.bicep --watch
```

### Deploy a Complete Platform

```bash
# 1. Clone the repository
git clone https://github.com/kkho/bicep-templates.git
cd bicep-templates

# 2. Validate deployment before rollout
az deployment group validate \
  --resource-group rg-platform-dev \
  --template-file deployments/main.bicep \
  --parameters resourceName=myapp-dev location=eastus

# 3. Deploy to development environment
az deployment group create \
  --resource-group rg-platform-dev \
  --template-file deployments/main.bicep \
  --parameters resourceName=myapp-dev location=eastus

# 4. Deploy to test environment
az deployment group create \
  --resource-group rg-platform-test \
  --template-file deployments/main.bicep \
  --parameters resourceName=myapp-test location=eastus

# 5. Deploy to production environment
az deployment group create \
  --resource-group rg-platform-prod \
  --template-file deployments/main.bicep \
  --parameters resourceName=myapp-prod location=eastus
```

## Repository Structure

### Modules (`/modules/`)

Reusable Bicep modules organized by service category:

```
modules/
├── networking/          # VNets, Subnets, NSGs, Application Gateway, Firewall
├── security/           # Key Vault, Managed Identity, Policies
├── compute/            # AKS, Virtual Machines
├── containers/         # Azure Container Registry, Container Apps
├── monitoring/         # Log Analytics, Application Insights, Alerts
│   ├── log-analytics-workspace/
│   ├── diagnostic-settings/
│   ├── data-collection/
│   └── operational-insights/
├── eventing/           # Event Grid, Service Bus
└── shared/             # Common utilities, telemetry
```

### Deployments (`/deployments/`)

Main deployment templates and orchestrators:

- `main.bicep` - Complete Azure platform deployment
- `network/` - Networking infrastructure
- `aks/` - **Production-ready AKS cluster (see `deployments/aks/main.bicep`)**

> **Note:**
>
> - The AKS solution now uses only three add-on modules from `modules/compute/aks/`: `aksdapr.bicep`, `aksfluxaddon.bicep`, and `akspolicies.bicep`.
> - All other legacy AKS modules in `modules/compute/aks/` are deprecated and can be deleted unless referenced elsewhere.

### Solution Examples

Ready-to-deploy solution architectures with different complexity levels:

#### 1. Basic Container Platform

**What it deploys:**

- AKS cluster with system and user node pools
- Azure Container Registry with private endpoints
- Basic networking with custom VNet
- Log Analytics workspace for monitoring

**Use case:** Development and testing environments

#### 2. Enterprise Container Platform

**What it deploys:**

- Hub-spoke networking with Azure Firewall
- Private AKS cluster with multiple node pools
- Azure Container Registry with vulnerability scanning
- Application Gateway with WAF
- Complete monitoring stack with diagnostic settings

**Use case:** Production-ready Kubernetes platform

#### 3. Secure Landing Zone

**What it deploys:**

- Hub-spoke network architecture
- Azure Firewall with policies
- Key Vault with private endpoints
- Bastion host for secure access
- Network Security Groups with flow logs

**Use case:** Secure foundation for Azure workloads

### Deploy Individual Modules

```bash
# Deploy ACR module
az deployment group create \
  --resource-group rg-containers \
  --template-file modules/containers/acr/main.bicep \
  --parameters @modules/containers/acr/examples/basic.bicepparam

# Deploy NSG module
az deployment group create \
  --resource-group rg-networking \
  --template-file modules/networking/nsg/main.bicep \
  --parameters @modules/networking/nsg/examples/aks-system-dev.bicepparam

# Deploy Key Vault module
az deployment group create \
  --resource-group rg-security \
  --template-file modules/keyvault/main.bicep \
  --parameters resourceName=mykv location=eastus
```

### Parameter File Examples

Each module includes example parameter files in the `examples/` directory:

```bash
# Use parameter files for consistent deployments
az deployment group create \
  --resource-group rg-platform \
  --template-file deployments/main.bicep \
  --parameters @deployments/examples/dev-platform.bicepparam
```

## Development

### Building and Testing

```bash
# Validate all templates
az bicep build --file deployments/main.bicep

# Validate specific module
az bicep build --file modules/containers/acr/main.bicep

# Check for errors across all modules
Get-ChildItem -Path "modules" -Filter "*.bicep" -Recurse |
  ForEach-Object { az bicep build --file $_.FullName }
```

### Project Structure Standards

- **Modules**: Self-contained, reusable components
- **Parameter files**: Environment-specific configurations
- **Documentation**: README.md in each module directory
- **Examples**: Working parameter file examples
- **RBAC**: Role assignments co-located with resources

### Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/awesome-feature`)
3. Add/modify templates following the established patterns
4. Update documentation and examples
5. Run validation tests (`az bicep build --file main.bicep`)
6. Commit changes (`git commit -m 'Add awesome feature'`)
7. Push to branch (`git push origin feature/awesome-feature`)
8. Submit pull request

## Additional Resources

- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Bicep Best Practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/best-practices)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
