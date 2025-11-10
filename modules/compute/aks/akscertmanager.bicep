@description('Name of the existing AKS cluster')
param aksName string

@description('Email address for Let\'s Encrypt certificate notifications')
param email string

@description('Let\'s Encrypt environment (staging or production)')
@allowed(['staging', 'production'])
param letsEncryptEnvironment string = 'staging'

@description('DNS zone name for DNS-01 challenge validation (optional)')
param dnsZoneName string = ''

@description('Azure Tenant ID for Azure DNS validation')
param azureTenantId string = ''

@description('Azure Subscription ID for Azure DNS validation')
param azureSubscriptionId string = ''

var letsEncryptServer = letsEncryptEnvironment == 'production'
  ? 'https://acme-v02.api.letsencrypt.org/directory'
  : 'https://acme-staging-v02.api.letsencrypt.org/directory'

@description('Get the location from resource group')
var deploymentLocation = resourceGroup().location

// This module deploys cert-manager using kubectl/helm commands
// In a real implementation, this would use AKS extensions or deployment scripts

// Deployment script to install cert-manager via Helm
resource certManagerInstall 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'cert-manager-install-${aksName}'
  location: deploymentLocation
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.63.0'
    timeout: 'PT30M'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'AKS_NAME'
        value: aksName
      }
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'EMAIL'
        value: email
      }
      {
        name: 'LETSENCRYPT_SERVER'
        value: letsEncryptServer
      }
      {
        name: 'DNS_ZONE'
        value: dnsZoneName
      }
      {
        name: 'TENANT_ID'
        value: azureTenantId
      }
      {
        name: 'SUBSCRIPTION_ID'
        value: azureSubscriptionId
      }
    ]
    scriptContent: '''
      #!/bin/bash
      set -e

      # Get AKS credentials
      az aks get-credentials --name $AKS_NAME --resource-group $RESOURCE_GROUP --overwrite-existing

      # Add Jetstack Helm repository
      helm repo add jetstack https://charts.jetstack.io
      helm repo update

      # Install cert-manager
      echo "Installing cert-manager..."
      helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.16.2 \
        --set crds.enabled=true \
        --set global.leaderElection.namespace=cert-manager \
        --wait

      # Wait for cert-manager to be ready
      kubectl wait --for=condition=Available --timeout=300s \
        deployment/cert-manager -n cert-manager
      kubectl wait --for=condition=Available --timeout=300s \
        deployment/cert-manager-webhook -n cert-manager
      kubectl wait --for=condition=Available --timeout=300s \
        deployment/cert-manager-cainjector -n cert-manager

      # Create ClusterIssuer for Let's Encrypt
      echo "Creating ClusterIssuer..."
      cat <<EOF | kubectl apply -f -
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt
      spec:
        acme:
          server: $LETSENCRYPT_SERVER
          email: $EMAIL
          privateKeySecretRef:
            name: letsencrypt-account-key
          solvers:
          - http01:
              ingress:
                class: nginx
      EOF

      # If DNS zone is provided, also create DNS-01 solver
      if [ ! -z "$DNS_ZONE" ]; then
        echo "Creating ClusterIssuer with DNS-01 solver..."
        cat <<EOF | kubectl apply -f -
        apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: letsencrypt-dns
        spec:
          acme:
            server: $LETSENCRYPT_SERVER
            email: $EMAIL
            privateKeySecretRef:
              name: letsencrypt-dns-account-key
            solvers:
            - dns01:
                azureDNS:
                  subscriptionID: $SUBSCRIPTION_ID
                  resourceGroupName: $RESOURCE_GROUP
                  hostedZoneName: $DNS_ZONE
                  environment: AzurePublicCloud
                  managedIdentity:
                    clientID: ""
      EOF
      fi

      echo "cert-manager installation completed successfully!"
    '''
  }
  identity: {
    type: 'SystemAssigned'
  }
}

@description('cert-manager installation status')
output status string = 'cert-manager installed successfully'

@description('Let\'s Encrypt server URL')
output letsEncryptServer string = letsEncryptServer

@description('ClusterIssuers created')
output clusterIssuers array = !empty(dnsZoneName)
  ? [
      'letsencrypt'
      'letsencrypt-dns'
    ]
  : [
      'letsencrypt'
    ]
