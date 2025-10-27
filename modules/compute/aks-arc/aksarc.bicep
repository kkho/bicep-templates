param azureLocation string
param customLocationResourceId string

// Logical Network Parameters
param logicalNetworkName string
param dnsServers array
param addressPrefix string
param vmSwitchName string
param ipAllocationMethod string
param vlan int
param vipPoolStart string
param vipPoolEnd string
param nextHopIpAddress string

// Provisioned Cluster
param connectedClusterName string
param sshPublicKey string
param controlPlaneHostIP string
param kubernetesVersion string = '1.24.6'
param controlPlaneVmSize string = 'Standard_DS2_v2'
param controlPlaneNodeCount int = 3
param nodePoolName string
param nodePoolVmSize string
@allowed(['Linux', 'Windows'])
param nodePoolOsType string = 'Linux'
param nodePoolCount int = 3
param nodePoolLabel string
param nodePoolLabelValue string
param nodePoolTaint string
param networkProfileNetworkPolicy string
param networkProfileLoadBalancerCount int

resource logicalNetwork 'Microsoft.AzureStackHCI/logicalNetworks@2024-01-01' = {
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationResourceId
  }
  location: azureLocation
  name: logicalNetworkName
  properties: {
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: [
      {
        name: 'bicepSubnet'
        properties: {
          addressPrefix: addressPrefix
          ipAllocationMethod: ipAllocationMethod
          vlan: vlan
          ipPools: [
            {
              name: 'bicepIPPool'
              start: vipPoolStart
              end: vipPoolEnd
              ipPoolType: 'vippool'
            }
          ]
          routeTable: {
            properties: {
              routes: [
                {
                  name: 'defaultRoute'
                  properties: {
                    addressPrefix: '0.0.0.0/0'
                    nextHopIpAddress: nextHopIpAddress
                  }
                }
              ]
            }
          }
        }
      }
    ]
    vmSwitchName: vmSwitchName
  }
}

// Create the connected cluster.
// This is the Arc representation of the AKS cluster, used to create a Managed Identity for the provisioned cluster.
resource connectedCluster 'Microsoft.Kubernetes/ConnectedClusters@2024-01-01' = {
  location: azureLocation
  name: connectedClusterName
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'ProvisionedCluster'
  properties: {
    // agentPublicKeyCertificate must be empty for provisioned clusters that will be created next.
    agentPublicKeyCertificate: ''
    aadProfile: {
      enableAzureRBAC: false
    }
  }
}

// Create the provisioned cluster instance. 
// This is the actual AKS cluster and provisioned on your Azure Local cluster via the Arc Resource Bridge.
resource provisionedClusterInstance 'Microsoft.HybridContainerService/provisionedClusterInstances@2024-01-01' = {
  name: 'default'
  scope: connectedCluster
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationResourceId
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    linuxProfile: {
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    controlPlane: {
      count: controlPlaneNodeCount
      controlPlaneEndpoint: {
        hostIP: controlPlaneHostIP
      }
      vmSize: controlPlaneVmSize
    }
    networkProfile: {
      networkPolicy: networkProfileNetworkPolicy
      loadBalancerProfile: {
        count: networkProfileLoadBalancerCount
      }
    }
    agentPoolProfiles: [
      {
        name: nodePoolName
        count: nodePoolCount
        vmSize: nodePoolVmSize
        osType: nodePoolOsType
        nodeLabels: {
          '${nodePoolLabel}': nodePoolLabelValue
        }
        nodeTaints: [
          nodePoolTaint
        ]
      }
    ]
    cloudProviderProfile: {
      infraNetworkProfile: {
        vnetSubnetIds: [
          logicalNetwork.id
        ]
      }
    }
    storageProfile: {
      nfsCsiDriver: {
        enabled: true
      }
      smbCsiDriver: {
        enabled: true
      }
    }
  }
}
