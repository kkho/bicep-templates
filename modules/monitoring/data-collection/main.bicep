param name string

param aksLawId string

param location string = resourceGroup().location

param createLaw bool

param isAnotherResourceCreated bool

param enableSysLog bool = false

resource sysLog 'Microsoft.Insights/dataCollectionRules@2023-03-11' = if (createLaw && isAnotherResourceCreated && enableSysLog) {
  name: '${name}-${location}-msci'
  location: location
  kind: 'Linux'
  properties: {
    dataFlows: [
      {
        destinations: [
          'ciworkspace'
        ]
        streams: [
          'Microsoft-Syslog'
          'Microsoft-ContainerInsights-Group-Default'
        ]
      }
    ]
    dataSources: {
      extensions: [
        {
          streams: [
            'Microsoft-ContainerInsights-Group-Default'
          ]
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Off'
            }
          }
          name: 'ContainerInsightsExtension'
        }
      ]
      syslog: [
        {
          facilityNames: [
            'auth'
            'authpriv'
            'cron'
            'daemon'
            'mark'
            'kern'
            'local0'
            'local1'
            'local2'
            'local3'
            'local4'
            'local5'
            'local6'
            'local7'
            'lpr'
            'mail'
            'news'
            'syslog'
            'user'
            'uucp'
          ]
          logLevels: [
            'Debug'
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
          name: 'sysLogsDataSource'

          streams: ['Microsoft-Syslog']
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'ciworkspace'
          workspaceResourceId: aksLawId
        }
      ]
    }
  }
}

resource association 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = if (createLaw && isAnotherResourceCreated && enableSysLog) {
  name: '${name}-${aksLawId}-association'
  scope: resourceGroup()
  properties: {
    dataCollectionRuleId: sysLog.id
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
  }
}
