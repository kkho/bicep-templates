param dnsZoneName string
param principalId string
param isPrivate bool
param vnetId string = ''

resource dns 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = if (!isPrivate) {
  name: dnsZoneName
}

resource privateDns 'Microsoft.Network/privateDnsZones@2024-06-01' existing = if (isPrivate) {
  name: dnsZoneName
}

var DNSZoneContributor = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'befefa01-2a29-4197-83a8-272ff33ce314'
)
resource dnsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: dns
  name: guid(dns.id, principalId, DNSZoneContributor)
  properties: {
    roleDefinitionId: DNSZoneContributor
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

var PrivateDNSZoneContributor = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'befefa01-2a29-4197-83a8-272ff33ce314'
)
resource privateDnsContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (isPrivate) {
  scope: privateDns
  name: guid(privateDns.id, principalId, PrivateDNSZoneContributor)
  properties: {
    roleDefinitionId: PrivateDNSZoneContributor
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

resource dns_vnet_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (isPrivate && !empty(vnetId)) {
  parent: privateDns
  name: take('${dnsZoneName}-vnetLink', 64)
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}
