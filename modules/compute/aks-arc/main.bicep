targetScope = 'subscription'

param azureLocation string
param deploymentResourceGroupName string
param customLocationResourceId string

// Logical network
param logicalNetworkName string
param addressPrefix string
param dnsServers array
param vmSwitchName string
param ipAllocationMethod string
param vlan int
param vipPoolStart string
param vipPoolEnd string
param nextHopIpAddress string

// Provisioned cluster
param connectedClusterName string
param sshPublicKey string
param controlPlaneHostIP string
param kubernetesVersion string
param controlPlaneVmSize string
param controlPlaneNodeCount int
param nodePoolName string
param nodePoolVmSize string
param nodePoolOsType string
param nodePoolCount int
param nodePoolLabel string
param nodePoolLabelValue string
param nodePoolTaint string
param networkProfileNetworkPolicy string
param networkProfileLoadBalancerCount int

resource deploymentResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: deploymentResourceGroupName
  location: azureLocation
}

module aksarcModule 'aksarc.bicep' = {
  name: '${deployment().name}-aksarc'
  scope: resourceGroup(deploymentResourceGroupName)
  params: {
    kubernetesVersion: kubernetesVersion
    controlPlaneVmSize: controlPlaneVmSize
    controlPlaneNodeCount: controlPlaneNodeCount
    nodePoolName: nodePoolName
    nodePoolVmSize: nodePoolVmSize
    nodePoolLabel: nodePoolLabel
    nodePoolLabelValue: nodePoolLabelValue
    nodePoolTaint: nodePoolTaint
    networkProfileLoadBalancerCount: networkProfileLoadBalancerCount
    networkProfileNetworkPolicy: networkProfileNetworkPolicy
    connectedClusterName: connectedClusterName
    controlPlaneHostIP: controlPlaneHostIP
    sshPublicKey: sshPublicKey
    nodePoolOsType: nodePoolOsType
    nodePoolCount: nodePoolCount
    customLocationResourceId: customLocationResourceId
    azureLocation: azureLocation
    addressPrefix: addressPrefix
    dnsServers: dnsServers
    ipAllocationMethod: ipAllocationMethod
    vlan: vlan
    vmSwitchName: vmSwitchName
    vipPoolStart: vipPoolStart
    vipPoolEnd: vipPoolEnd
    nextHopIpAddress: nextHopIpAddress
    logicalNetworkName: logicalNetworkName
  }
  dependsOn: [
    deploymentResourceGroup
  ]
}
