using '../aksarc.bicep'

// Production environment parameters for AKS Arc
param azureLocation = 'eastus2'
param customLocationResourceId = '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-arc-prod/providers/Microsoft.ExtendedLocation/customLocations/cl-prod'

// Logical Network Parameters
param logicalNetworkName = 'ln-aks-arc-prod'
param dnsServers = ['168.63.129.16', '8.8.8.8'] // Azure DNS + Google DNS backup
param addressPrefix = '10.0.0.0/16' // Larger network for production
param vmSwitchName = 'aks-prod-switch'
param ipAllocationMethod = 'Static'
param vlan = 200
param vipPoolStart = '10.0.1.200'
param vipPoolEnd = '10.0.1.250'
param nextHopIpAddress = '10.0.0.1'

// Provisioned Cluster Parameters
param connectedClusterName = 'aks-arc-prod'
param sshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...' // Replace with your SSH public key
param controlPlaneHostIP = '10.0.1.100'
param kubernetesVersion = '1.28.3'
param controlPlaneVmSize = 'Standard_DS4_v2' // Larger for production
param controlPlaneNodeCount = 3 // HA setup for production
param nodePoolName = 'nodepool-prod'
param nodePoolVmSize = 'Standard_DS4_v2' // Larger VMs for production
param nodePoolOsType = 'Linux'
param nodePoolCount = 5 // More nodes for production workload
param nodePoolLabel = 'environment'
param nodePoolLabelValue = 'production'
param nodePoolTaint = 'environment=prod:NoSchedule'
param networkProfileNetworkPolicy = 'azure' // Azure CNI for production
param networkProfileLoadBalancerCount = 2 // Redundancy for production
