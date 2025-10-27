using '../aksarc.bicep'

// Development environment parameters for AKS Arc
param azureLocation = 'eastus2'
param customLocationResourceId = '/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-arc-dev/providers/Microsoft.ExtendedLocation/customLocations/cl-dev'

// Logical Network Parameters
param logicalNetworkName = 'ln-aks-arc-dev'
param dnsServers = ['8.8.8.8', '8.8.4.4']
param addressPrefix = '192.168.1.0/24'
param vmSwitchName = 'aks-dev-switch'
param ipAllocationMethod = 'Static'
param vlan = 100
param vipPoolStart = '192.168.1.200'
param vipPoolEnd = '192.168.1.220'
param nextHopIpAddress = '192.168.1.1'

// Provisioned Cluster Parameters
param connectedClusterName = 'aks-arc-dev'
param sshPublicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...' // Replace with your SSH public key
param controlPlaneHostIP = '192.168.1.100'
param kubernetesVersion = '1.28.3'
param controlPlaneVmSize = 'Standard_DS2_v2'
param controlPlaneNodeCount = 1 // Smaller for dev
param nodePoolName = 'nodepool-dev'
param nodePoolVmSize = 'Standard_DS2_v2'
param nodePoolOsType = 'Linux'
param nodePoolCount = 2 // Smaller for dev
param nodePoolLabel = 'environment'
param nodePoolLabelValue = 'development'
param nodePoolTaint = 'environment=dev:NoSchedule'
param networkProfileNetworkPolicy = 'calico'
param networkProfileLoadBalancerCount = 1
