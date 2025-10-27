param existingAksName string

@description('Add the Dapr extension')
param daprAddon bool = false

@description('Enable high availability (HA) mode for the Dapr control plane')
param daprAddonHA bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: existingAksName
}

resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2022-11-01' = if (daprAddon) {
  name: 'dapr'
  scope: aks
  properties: {
    extensionType: 'Microsoft.Dapr'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    configurationSettings: {
      'global.ha.enabled': '${daprAddonHA}'
    }
    scope: {
      cluster: {
        releaseNamespace: 'dapr-system'
      }
    }
    configurationProtectedSettings: {}
  }
}

output daprReleaseNamespace string = daprAddon ? daprExtension.properties.scope.cluster.releaseNamespace : ''
