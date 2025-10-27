param existingAksName string
param fluxGitOpsAddOn bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: existingAksName
}

resource fluxAddOn 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = if (fluxGitOpsAddOn) {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    configurationProtectedSettings: {}
  }
}

output fluxReleaseNameSpace string = fluxGitOpsAddOn ? fluxAddOn.properties.scope.cluster.releaseNamespace : ''
