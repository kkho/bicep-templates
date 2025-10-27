param id string = ''
param contributor string = ''
param principalId string = ''

resource appGwAGICContrib 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(id, 'Agic', contributor)
  properties: {
    roleDefinitionId: contributor
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}
