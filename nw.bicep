
param mytags object
param targetRg string

resource applyTags 'Microsoft.Resources/tags@2025-03-01' = {
  name: 'default'
  scope: resourceGroup()
  properties: {
    tags: mytags
  }
}

var suffix = replace(targetRg, '-', '')
var saName = 'sto${suffix}'

resource sa 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: saName
  scope: resourceGroup(targetRg)
}

resource nw 'Microsoft.Network/networkWatchers@2024-05-01' existing = {
  name: 'NetworkWatcher_eastus2euap'
}

resource applyTagsNw 'Microsoft.Resources/tags@2025-03-01' = {
  name: 'default'
  scope: nw
  properties: {
    tags: mytags
  }
}

var nics = [
  'nic1'
  'nic2'
]

resource nicsr 'Microsoft.Network/networkInterfaces@2024-05-01' existing = [for nic in nics: {
  name: nic
  scope: resourceGroup(targetRg)
}
]

resource flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2024-05-01' = [for (nic, i) in nics: {
  location: 'eastus2euap' // tricky one right there

  tags: mytags
  name: '${nic}-${targetRg}-flowlog'
  parent: nw

  properties: {
    storageId: sa.id
    targetResourceId: nicsr[i].id
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: false
      }
    }
    enabled: true
    retentionPolicy: {
      days: 1
    }
  }
}
]
