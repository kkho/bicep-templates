# SSL Certificates, SSH Keys, and Domain Name Configuration Guide

This guide explains how to configure SSL/TLS certificates, SSH access to AKS nodes, DNS records, and automatic certificate management using cert-manager in your AKS deployment.

---

## 🔐 1. SSL/TLS Certificates for Application Gateway

### Overview

The template supports HTTPS termination at the Application Gateway using SSL certificates stored in Azure Key Vault.

### Architecture Flow

```
Internet → Application Gateway (HTTPS:443) → AKS Ingress (HTTP:80) → Pods
          ↓ (SSL Termination)
     Key Vault Certificate
```

### Prerequisites

1. **Existing Key Vault** with your SSL certificate
2. **Certificate in Key Vault** (PFX format with private key)
3. **Managed Identity** (automatically created by template)

### Configuration Steps

#### Step 1: Upload Certificate to Key Vault

```powershell
# Convert PEM to PFX if needed
openssl pkcs12 -export -out certificate.pfx \
  -inkey privatekey.pem \
  -in certificate.crt

# Upload to Key Vault
az keyvault certificate import \
  --vault-name kv-prodcerts \
  --name ssl-certificate \
  --file certificate.pfx
```

#### Step 2: Enable SSL in Parameters

```bicep
// In enterprise-production.bicepparam
param enableApplicationGateway = true
param enableSslCertificate = true
param sslCertificateKeyVaultName = 'kv-prodcerts' // Your Key Vault name
param sslCertificateSecretName = 'ssl-certificate' // Certificate name
param sslCustomDomain = 'www.mycompany.com' // Your domain
```

### How It Works

1. **Managed Identity Creation**

   ```bicep
   module appGwManagedIdentity 'avm/res/managed-identity/user-assigned-identity'
   ```

   - Template creates a User-Assigned Managed Identity for Application Gateway
   - Identity is granted `Get` permissions on Key Vault secrets and certificates

2. **Key Vault Access Policy**

   ```bicep
   resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2025-05-01'
   ```

   - Automatically grants the managed identity access to retrieve certificates
   - Permissions: `secrets/get`, `certificates/get`

3. **Certificate Configuration**

   ```bicep
   sslCertificates: [
     {
       name: 'sslCertificate'
       keyVaultSecretId: 'https://kv-prodcerts.vault.azure.net/secrets/ssl-certificate'
     }
   ]
   ```

4. **HTTPS Listener**

   ```bicep
   httpListeners: [
     {
       name: 'httpsListener'
       protocol: 'Https'
       sslCertificateName: 'sslCertificate'
       hostName: 'www.mycompany.com'
     }
   ]
   ```

5. **HTTP to HTTPS Redirect**
   ```bicep
   redirectConfigurations: [
     {
       name: 'httpToHttpsRedirect'
       redirectType: 'Permanent'
       targetListenerName: 'httpsListener'
     }
   ]
   ```

### SSL Policy

The template applies the strong SSL policy `AppGwSslPolicy20220101S`:

- **Min Protocol**: TLS 1.2
- **Cipher Suites**: Modern, secure ciphers only
- **Perfect Forward Secrecy**: Enabled

---

## 🔑 2. SSH Access to AKS Nodes

### Overview

Enable SSH access to AKS nodes for troubleshooting and maintenance. This configures the Linux profile on AKS with your public key.

### Security Considerations

⚠️ **Production Best Practice**:

- SSH access should be restricted in production
- Use Azure Bastion + Private AKS cluster for secure access
- Rotate SSH keys regularly
- Consider disabling after initial setup

### Configuration Steps

#### Step 1: Generate SSH Key Pair

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -C "aks-admin@mycompany.com" -f ~/.ssh/aks-nodes

# View public key
cat ~/.ssh/aks-nodes.pub
```

#### Step 2: Enable SSH in Parameters

```bicep
// In your .bicepparam file
param enableSshAccess = true
param sshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... aks-admin@mycompany.com'
param aksAdminUsername = 'aksadmin' // Default: 'azureuser'
```

### How It Works

1. **Linux Profile Configuration**

   ```bicep
   // In AKS cluster module
   sshPublicKey: enableSshAccess && !empty(sshPublicKey) ? sshPublicKey : null
   adminUsername: enableSshAccess ? aksAdminUsername : null
   ```

2. **Node Access**

   ```bash
   # Get node name
   kubectl get nodes

   # SSH to node (if public IP enabled)
   ssh aksadmin@<node-public-ip>

   # Or via kubectl debug (recommended)
   kubectl debug node/<node-name> -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0
   ```

### Access Methods

#### Method 1: Direct SSH (Development Only)

```bash
# Get node public IP (if enableNodePublicIP=true)
kubectl get nodes -o wide
ssh aksadmin@<node-ip>
```

#### Method 2: Via Jump Host (Recommended)

```bash
# SSH through Azure Bastion
az network bastion ssh \
  --name bastion-prodaks \
  --resource-group rg-prodaks \
  --target-resource-id <vm-resource-id> \
  --auth-type ssh-key \
  --username aksadmin \
  --ssh-key ~/.ssh/aks-nodes
```

#### Method 3: kubectl debug (Most Secure)

```bash
# Create debug pod with node access
kubectl debug node/<node-name> -it --image=ubuntu
```

---

## 🌐 3. DNS Records for Application Gateway

### Overview

Automatically create DNS A records pointing to the Application Gateway public IP for custom domains.

### Architecture

```
www.mycompany.com (DNS A Record)
    ↓
Application Gateway Public IP (Static)
    ↓
Application Gateway
    ↓
AKS Ingress
```

### Prerequisites

1. **Azure DNS Zone** created and delegated
2. **Domain registrar** NS records pointing to Azure DNS
3. **Application Gateway** with static public IP

### Configuration Steps

#### Step 1: Create DNS Zone

The template creates this automatically when `enableDnsZone=true`:

```bicep
param enableDnsZone = true
param dnsZoneName = 'mycompany.com' // Your root domain
```

#### Step 2: Delegate Domain

In your domain registrar (e.g., GoDaddy, Namecheap), set NS records to Azure DNS:

```
ns1-01.azure-dns.com
ns2-01.azure-dns.net
ns3-01.azure-dns.org
ns4-01.azure-dns.info
```

#### Step 3: Enable DNS A Record

```bicep
param enableDnsARecord = true
param dnsARecordName = 'www' // Creates www.mycompany.com
// Use '@' for root domain (mycompany.com)
```

### How It Works

1. **Static Public IP**

   ```bicep
   module appGwPublicIp 'avm/res/network/public-ip-address' = {
     params: {
       publicIPAllocationMethod: 'Static' // Critical for DNS
       zones: [1, 2, 3] // Zone redundancy
     }
   }
   ```

2. **DNS A Record Creation**

   ```bicep
   resource dnsARecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
     name: '${dnsZoneName}/${dnsARecordName}'
     properties: {
       TTL: 3600 // 1 hour TTL
       targetResource: {
         id: appGwPublicIp.outputs.resourceId // Points to App Gateway IP
       }
     }
   }
   ```

3. **Automatic Updates**
   - Azure manages the IP address in the A record
   - If Application Gateway is recreated, DNS updates automatically
   - No manual IP management required

### DNS Record Examples

| Configuration            | Result              | Use Case                  |
| ------------------------ | ------------------- | ------------------------- |
| `dnsARecordName = 'www'` | `www.mycompany.com` | Main website              |
| `dnsARecordName = 'api'` | `api.mycompany.com` | API endpoint              |
| `dnsARecordName = '@'`   | `mycompany.com`     | Root domain               |
| `dnsARecordName = '*'`   | `*.mycompany.com`   | Wildcard (all subdomains) |

### Verification

```bash
# Check DNS propagation
nslookup www.mycompany.com

# Test HTTPS connection
curl -I https://www.mycompany.com

# View Azure DNS records
az network dns record-set a list \
  --resource-group rg-prodaks \
  --zone-name mycompany.com
```

---

## 🤖 4. Automatic Certificate Management with cert-manager

### Overview

cert-manager automates Let's Encrypt certificate issuance and renewal for Kubernetes ingress resources.

### Architecture

```
cert-manager → Let's Encrypt → DNS-01/HTTP-01 Challenge → Certificate Issued
     ↓                                                              ↓
 Kubernetes Secret ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
     ↓
 Ingress Controller (uses TLS secret)
```

### Prerequisites

1. **DNS Zone** (for DNS-01 validation)
2. **Email Address** for Let's Encrypt notifications
3. **Ingress Controller** (nginx, traefik, etc.)

### Configuration Steps

#### Step 1: Enable cert-manager

```bicep
// In your .bicepparam file
param enableCertManager = true
param certManagerEmail = 'admin@mycompany.com'
param letsEncryptEnvironment = 'staging' // Use 'staging' for testing
```

#### Step 2: Deploy Template

The template will:

1. Install cert-manager via Helm
2. Create ClusterIssuer for Let's Encrypt
3. Configure DNS-01 solver (if DNS zone enabled)
4. Configure HTTP-01 solver

### How It Works

1. **cert-manager Installation**

   ```bash
   # Deployed via Deployment Script
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --version v1.16.2 \
     --set crds.enabled=true
   ```

2. **ClusterIssuer Creation**

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: admin@mycompany.com
       privateKeySecretRef:
         name: letsencrypt-account-key
       solvers:
         - http01:
             ingress:
               class: nginx
   ```

3. **DNS-01 Solver (Optional)**
   ```yaml
   - dns01:
       azureDNS:
         subscriptionID: <subscription-id>
         resourceGroupName: <rg-name>
         hostedZoneName: mycompany.com
   ```

### Usage Examples

#### Example 1: Ingress with Let's Encrypt Certificate

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt"
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
    - hosts:
        - www.mycompany.com
      secretName: tls-my-app # cert-manager creates this
  rules:
    - host: www.mycompany.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

#### Example 2: Certificate Resource

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-domain-cert
  namespace: default
spec:
  secretName: my-domain-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
    - www.mycompany.com
    - api.mycompany.com
```

### Validation Methods

#### HTTP-01 Challenge

- **Pros**: Simple, works with any DNS provider
- **Cons**: Requires ingress controller, port 80 open
- **Use When**: Single domain, public-facing ingress

#### DNS-01 Challenge

- **Pros**: Works with wildcards, no ingress required
- **Cons**: Requires Azure DNS integration
- **Use When**: Wildcard certificates, private clusters

### Let's Encrypt Environments

| Environment    | Server                                 | Use Case   | Rate Limits   |
| -------------- | -------------------------------------- | ---------- | ------------- |
| **Staging**    | `acme-staging-v02.api.letsencrypt.org` | Testing    | No limits     |
| **Production** | `acme-v02.api.letsencrypt.org`         | Production | 50 certs/week |

⚠️ **Always test with staging first!** Production has strict rate limits.

### Certificate Lifecycle

1. **Issuance**: cert-manager requests certificate from Let's Encrypt
2. **Validation**: HTTP-01 or DNS-01 challenge completed
3. **Storage**: Certificate stored in Kubernetes Secret
4. **Renewal**: Automatic renewal 30 days before expiration
5. **Update**: Ingress automatically uses new certificate

### Monitoring Certificates

```bash
# Check certificate status
kubectl get certificates -A

# View certificate details
kubectl describe certificate my-domain-cert

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# View certificate expiration
kubectl get certificate my-domain-cert -o jsonpath='{.status.notAfter}'
```

---

## 🎯 Complete Production Example

### Scenario

Deploy an AKS cluster with:

- Custom domain: `www.mycompany.com`
- HTTPS with Let's Encrypt
- SSH access for troubleshooting
- Application Gateway with SSL termination

### Configuration

```bicep
// enterprise-production.bicepparam

// DNS
param enableDnsZone = true
param dnsZoneName = 'mycompany.com'
param enableDnsARecord = true
param dnsARecordName = 'www'

// Application Gateway
param enableApplicationGateway = true
param applicationGatewaySku = 'WAF_v2'

// SSL Certificate (from Key Vault for App Gateway)
param enableSslCertificate = true
param sslCertificateKeyVaultName = 'kv-prodcerts'
param sslCertificateSecretName = 'ssl-certificate'
param sslCustomDomain = 'www.mycompany.com'

// cert-manager (for Kubernetes ingress)
param enableCertManager = true
param certManagerEmail = 'admin@mycompany.com'
param letsEncryptEnvironment = 'production'

// SSH Access
param enableSshAccess = true
param sshPublicKey = 'ssh-rsa AAAAB3Nza...'
param aksAdminUsername = 'aksadmin'
```

### Deployment

```powershell
# Deploy infrastructure
az deployment group create \
  --resource-group rg-prodaks \
  --template-file main.bicep \
  --parameters examples/enterprise-production.bicepparam

# Verify DNS
nslookup www.mycompany.com

# Get AKS credentials
az aks get-credentials --resource-group rg-prodaks --name aks-prodaks

# Check cert-manager
kubectl get pods -n cert-manager

# Deploy sample app with HTTPS
kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/ingress.yaml
```

---

## 🔧 Troubleshooting

### SSL Certificate Issues

**Problem**: Application Gateway can't access certificate

```bash
# Check managed identity
az identity show --name id-appgw-prodaks --resource-group rg-prodaks

# Check Key Vault access policy
az keyvault show --name kv-prodcerts --query properties.accessPolicies
```

**Solution**: Ensure managed identity has `Get` permissions on secrets and certificates.

### DNS Issues

**Problem**: DNS not resolving

```bash
# Check DNS zone
az network dns zone show --name mycompany.com --resource-group rg-prodaks

# Check A record
az network dns record-set a show \
  --name www \
  --zone-name mycompany.com \
  --resource-group rg-prodaks
```

**Solution**: Verify NS records at domain registrar match Azure DNS name servers.

### cert-manager Issues

**Problem**: Certificate not issuing

```bash
# Check certificate status
kubectl describe certificate my-cert

# Check challenges
kubectl get challenges -A

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f
```

**Common Issues**:

- HTTP-01: Ensure port 80 is accessible
- DNS-01: Verify Azure DNS permissions
- Rate Limits: Use staging environment for testing

### SSH Issues

**Problem**: Can't SSH to nodes

```bash
# Check if SSH is enabled
az aks show --name aks-prodaks --resource-group rg-prodaks \
  --query linuxProfile
```

**Solution**: Ensure `enableSshAccess=true` and valid SSH public key provided.

---

## 📚 References

- [Application Gateway SSL Termination](https://learn.microsoft.com/azure/application-gateway/ssl-overview)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [AKS SSH Access](https://learn.microsoft.com/azure/aks/node-access)
- [Azure DNS Documentation](https://learn.microsoft.com/azure/dns/)
