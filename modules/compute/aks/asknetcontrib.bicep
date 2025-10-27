param byoAKSSubnetId string
param byoAKSPodSubnetId string
param user_identity_principalId string

@allowed([
  'Subnet'
  'Vnet'
])
param rbacAssignmentScope string = 'Subnet'

var networkContributorRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4d97b98b-1d4f-4787-a291-c67834d212e7'
)

var existingAksPodSubnetName = !empty(byoAKSPodSubnetId) ? split(byoAKSPodSubnetId, '/')[10] : ''
var existingAksSubnetName = !empty(byoAKSSubnetId) ? split(byoAKSSubnetId, '/')[10] : ''
var existingAksVnetName = !empty(byoAKSSubnetId) ? split(byoAKSSubnetId, '/')[8] : ''

resource existingvnet 'Microsoft.Network/virtualNetworks@2024-10-01' existing = {
  name: existingAksVnetName
}

resource existingAksSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-10-01' existing = {
  parent: existingvnet
  name: existingAksSubnetName
}

resource existingAksPodSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-10-01' existing = if (!empty(byoAKSPodSubnetId)) {
  parent: existingvnet
  name: existingAksPodSubnetName
}

resource subnetRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (rbacAssignmentScope == 'Subnet') {
  name: guid(user_identity_principalId, networkContributorRole, existingAksSubnetName)
  scope: existingAksSubnet
  properties: {
    roleDefinitionId: networkContributorRole
    principalId: user_identity_principalId
    principalType: 'ServicePrincipal'
  }
}

resource podSubnetRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (rbacAssignmentScope == 'subnet') {
  name: guid(user_identity_principalId, networkContributorRole, existingAksPodSubnetName)
  scope: existingAksPodSubnet
  properties: {
    roleDefinitionId: networkContributorRole
    principalId: user_identity_principalId
    principalType: 'ServicePrincipal'
  }
}

resource existingVnetRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (rbacAssignmentScope != 'subnet') {
  name: guid(user_identity_principalId, networkContributorRole, existingAksVnetName)
  scope: existingvnet
  properties: {
    roleDefinitionId: networkContributorRole
    principalId: user_identity_principalId
    principalType: 'ServicePrincipal'
  }
}
