@description('Location for all resources.')
param location string = resourceGroup().location

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
param adminKey string
param adminUsername string = 'cloud-user'

@description('The size of the VM')
param vmSize string = 'Standard_E2s_v5'

param mytags object = {}
param saRules array = [{ value: '0.0.0.0/0', action: 'Allow' }]
param nsgRules array = ['0.0.0.0/0']
param saName string = 'sbxfrigo'

param privateEndpointVNetPolicies string = 'Basic'
// @secure() flemme
param dbPass string = 'nof284jksnf2j3k4n1m,nfs1/djks121nms,'

resource applyTags 'Microsoft.Resources/tags@2024-11-01' = {
  name: 'default'
  scope: resourceGroup()
  properties: {
    tags: mytags
  }
}

resource spoke1Avset 'Microsoft.Compute/availabilitySets@2024-11-01' existing = {
  name: 'spoke1Avset'
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  location: location
  name: 'vnet'
  tags: mytags
  properties: {
    privateEndpointVNetPolicies:  privateEndpointVNetPolicies
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
        'fd00::/42'
      ]
    }
  }
}

resource vnetfw 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  location: location
  name: 'vnetfw'
  tags: mytags
  properties: {
    privateEndpointVNetPolicies: privateEndpointVNetPolicies
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/24'
        'fdff::/42'
      ]
    }
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  location: location
  name: 'vnet2'
  tags: mytags
  properties: {
    privateEndpointVNetPolicies: privateEndpointVNetPolicies
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
        'fd02::/42'
      ]
    }
  }
}

resource vnetpl 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  location: location
  name: 'vnetpl'
  tags: mytags
  properties: {
    privateEndpointVNetPolicies: privateEndpointVNetPolicies
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
        'fd03::/42'
      ]
    }
  }
}

// needed for IPv6 lb
resource nsgdummy 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsgdummy'
  tags: mytags
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg'
  tags: mytags
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh'
        properties: {
          description: 'ssh access for me'
          access: 'Allow'
          direction: 'Inbound'
          priority: 101
          protocol: 'Tcp'
          destinationPortRange: '22'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          sourceAddressPrefixes: nsgRules
        }
      }
    ]
  }
}

resource rt 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt'
  tags: mytags
  location: location
  properties: {
    routes: [
      {
        name: 'myrt1'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '10.0.0.0/8'
          nextHopIpAddress: '192.168.0.10'
        }
      }
      {
        name: 'extraips'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '192.168.128.0/17'
          nextHopIpAddress: '10.0.0.4'
        }
      }
      {
        name: 'myrt6'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: 'fd00::/12'
          nextHopIpAddress: 'fdff::9999'
        }
      }
    ]
  }
}

resource rt2 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt2'
  tags: mytags
  location: location
  properties: {
    routes: [
      {
        name: 'myrt2'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '10.0.0.0/8'
          nextHopIpAddress: '192.168.0.10'
        }
      }
      {
        name: 'extraips'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '192.168.128.0/17'
          nextHopIpAddress: '192.168.0.10'
        }
      }
      {
        name: 'myrt6'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: 'fd00::/12'
          nextHopIpAddress: 'fdff::9999'
        }
      }
    ]
  }
}

resource rtfw 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rtfw'
  tags: mytags
  location: location
  properties: {
    routes: [
      {
        name: 'extraips'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '192.168.128.0/17'
          nextHopIpAddress: '10.0.0.4'
        }
      }
    ]
  }
}

resource rtpl 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rtpl'
  tags: mytags
  location: location
  properties: {
    routes: [
      {
        name: 'def'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '10.0.0.0/8'
          nextHopIpAddress: '192.168.0.10'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'subnet'
  properties: {
    addressPrefixes: [
      '10.0.0.0/24'
      'fd00::/64'
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: rt.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet2
  name: 'subnet2'
  properties: {
    addressPrefixes: [
      '10.2.0.0/24'
      'fd02::/64'
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: rt2.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

resource subnetpl 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnetpl
  name: 'subnetpl'
  properties: {
    addressPrefixes: [
      '10.3.0.0/24'
      'fd03::/64'
    ]
    routeTable: {
      id: rtpl.id
    }
    // privateEndpointNetworkPolicies: 'RouteTableEnabled'
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

resource subnetfw 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnetfw
  name: 'subnetfw'
  properties: {
    networkSecurityGroup: {
      id: nsgdummy.id
    }
    addressPrefixes: [
      '192.168.0.0/24'
      'fdff::/64'
    ]
    routeTable: {
      id: rtfw.id
    }
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

resource nic1 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nic1'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          privateIPAddressPrefixLength: 24
          publicIPAddress: {
            id: pip.id
          }
        }
      }
      {
        name: 'ipconfig2'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.5'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig3'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.6'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig4'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.7'
          privateIPAddressPrefixLength: 24
        }
      }
    ]
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nic2'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          subnet: {
            id: subnet2.id
          }
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.2.0.4'
          privateIPAddressPrefixLength: 24
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', dlb.name, 'poold')
            }
          ]
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip'
  tags: mytags
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  tags: mytags
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'

    networkAcls: {
      defaultAction: 'Deny'
      ipRules: saRules
    }
  }
}

resource autoShutdownConfig1 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-vm1'
  tags: mytags
  location: location
  properties: {
    status: 'Enabled'

    dailyRecurrence: {
      time: '02:00'
    }
    timeZoneId: 'UTC'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: vm1.id
  }
}

resource autoShutdownConfig2 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-vm2'
  tags: mytags
  location: location
  properties: {
    status: 'Enabled'

    dailyRecurrence: {
      time: '02:00'
    }
    timeZoneId: 'UTC'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: vm2.id
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm1'
  location: location
  tags: mytags
  identity: {
    type: 'SystemAssigned'
  }
  zones: [
    '3'
  ]
  properties: {
    priority: 'Regular'

    hardwareProfile: {
      vmSize: vmSize
    }

    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }

    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        name: 'os_vm1'
        caching: 'ReadOnly'
        osType: 'Linux'
      }
      // az vm image list --publisher RedHat --offer rhel-byos --sku rhel-lvm-94-gen2 --all
      // az vm image terms accept --urn RedHat:rhel-byos:rhel-..

      imageReference: {
        offer: 'rhel-byos'
        publisher: 'RedHat'
        sku: 'rhel-lvm94-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'vm1'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/cloud-user/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloudinit_rhel.yaml')
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: sa.properties.primaryEndpoints.blob
      }
    }
  }
  plan: {
    name: 'rhel-lvm94-gen2'
    product: 'rhel-byos'
    publisher: 'redhat'
  }
}

resource vm2 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm2'
  location: location
  tags: mytags
  identity: {
    type: 'SystemAssigned'
  }
  zones: [
    '3'
  ]
  properties: {
    priority: 'Regular'

    hardwareProfile: {
      vmSize: vmSize
    }

    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }

    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        name: 'os_vm2'
        caching: 'ReadOnly'
        osType: 'Linux'
      }

      imageReference: {
        offer: 'rhel-byos'
        publisher: 'RedHat'
        sku: 'rhel-lvm94-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'vm2'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/cloud-user/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloudinit_rhel.yaml')
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: sa.properties.primaryEndpoints.blob
      }
    }
  }
  plan: {
    name: 'rhel-lvm94-gen2'
    product: 'rhel-byos'
    publisher: 'redhat'
  }
}

resource lb 'Microsoft.Network/loadBalancers@2024-01-01' = {
  name: 'lb'
  tags: mytags
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    backendAddressPools: [
      {
        name: 'pool1'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'fipc'
        properties: {
          subnet: {
            id: subnetfw.id
          }
          privateIPAddress: '192.168.0.10'
          privateIPAllocationMethod: 'Static'
        }
        zones: [
          '3'
        ]
      }
    ]
    loadBalancingRules: [
      {
        name: 'rul'
        properties: {
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb', 'probe')
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: false
          enableTcpReset: true
          loadDistribution: 'SourceIP'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'lb', 'fipc')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb', 'pool1')
          }
        }
      }
    ]
    probes: [
      {
        name: 'probe'
        properties: {
          port: 22
          protocol: 'Tcp'
          probeThreshold: 2
        }
      }
    ]
  }
}

resource nicfw 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nicfw'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfigfw'
        properties: {
          subnet: {
            id: subnetfw.id
          }
          primary: true
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb.name, 'pool1')
            }
          ]
        }
      }
    ]
  }
}

resource nicfw2 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nicfw2'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfigfw'
        properties: {
          subnet: {
            id: subnetfw.id
          }
          primary: true
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb.name, 'pool1')
            }
          ]
        }
      }
    ]
  }
}

resource fw 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: 'fw1'
  location: location
  // tags: union(mytags, {disableSnatOnPL: 'true'})
  tags: mytags
  identity: {
    type: 'SystemAssigned'
  }
  
  properties: {

    availabilitySet: {
      id: spoke1Avset.id
    }

    hardwareProfile: {
      vmSize: vmSize
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nicfw.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]  
    }
    
  
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      imageReference: {
        offer: 'rhel-byos'
        publisher: 'RedHat'
        sku: 'rhel-lvm94-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        osType: 'Linux'
        name: 'os_fw1'
        deleteOption: 'Delete'
      }
    }
      
    osProfile: {
      computerName: 'fw1'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        
        ssh: {
          publicKeys: [
            {
              path: '/home/cloud-user/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloudinit_rhel_fw.yaml')
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: sa.properties.primaryEndpoints.blob
      }
    }
    
  }
  plan: {
    name: 'rhel-lvm94-gen2'
    product: 'rhel-byos'
    publisher: 'redhat'
  }
}

resource netpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peer1'
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnetfw.id
    }
  }
}
resource netpeer2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peer2'
  parent: vnet2
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnetfw.id
    }
  }
}
resource netpeerpl 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peerpl'
  parent: vnetpl
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnetfw.id
    }
  }
}
resource netpeerfw1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peerfw1'
  parent: vnetfw
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnet.id
    }
  }
}
resource netpeerfw2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peerfw2'
  parent: vnetfw
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnet2.id
    }
  }
}
resource netpeerfwpl 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'peerfwpl'
  parent: vnetfw
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: vnetpl.id
    }
  }
}

resource dlb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'dlb'
  tags: mytags
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    backendAddressPools: [
      {
        name: 'poold'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'fipd'
        properties: {
          subnet: {
            id: subnet2.id
          }
          privateIPAddress: '10.2.0.10'
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rul'
        properties: {
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'dlb', 'probed')
          }
          protocol: 'Tcp'
          frontendPort: 12345
          backendPort: 12345
          enableFloatingIP: true
          enableTcpReset: true
          loadDistribution: 'SourceIP'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'dlb', 'fipd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'dlb', 'poold')
          }
        }
      }
      {
        name: 'rul2'
        properties: {
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'dlb', 'probed')
          }
          protocol: 'Tcp'
          frontendPort: 8080
          backendPort: 8080
          enableFloatingIP: true
          enableTcpReset: true
          loadDistribution: 'SourceIP'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'dlb', 'fipd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'dlb', 'poold')
          }
        }
      }
    ]
    probes: [
      {
        name: 'probed'
        properties: {
          port: 22
          protocol: 'Tcp'
          probeThreshold: 2
        }
      }
    ]
  }
}

resource fileser 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  name: 'default'
  parent: sa
}

resource sha 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: 'sha'
  parent: fileser
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe'
  location: location
  tags: mytags
  properties: {
    subnet: {
      id: subnetpl.id
    }
    customNetworkInterfaceName: 'pe.nic'
    privateLinkServiceConnections: [
      {
        name: 'pe'
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: 'sqlfrigo'
  location: location
  tags: mytags
  properties: {
    administratorLogin: 'toto'
    restrictOutboundNetworkAccess: 'Enabled'
    administratorLoginPassword: dbPass
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: 'db'
  location: location
  tags: mytags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource privateEndpoint2 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe2'
  location: location
  tags: mytags
  properties: {
    subnet: {
      id: subnetpl.id
    }
    customNetworkInterfaceName: 'pe2.nic'
    privateLinkServiceConnections: [
      {
        name: 'pe2'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource fw2 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: 'fw2'
  location: location
  // tags: union(mytags, {disableSnatOnPL: 'true'})
  tags: mytags
  identity: {
    type: 'SystemAssigned'
  }

  zones: [
    '3'
  ]
  properties: {
  

    hardwareProfile: {
      vmSize: vmSize
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nicfw2.id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]  
    }
    
  
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      imageReference: {
        offer: 'rhel-byos'
        publisher: 'RedHat'
        sku: 'rhel-lvm94-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        osType: 'Linux'
        name: 'os_fw2'
        deleteOption: 'Delete'
      }
    }
      
    osProfile: {
      computerName: 'fw2'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        
        ssh: {
          publicKeys: [
            {
              path: '/home/cloud-user/.ssh/authorized_keys'
              keyData: adminKey
            }
          ]
        }
      }
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloudinit_rhel_fw.yaml')
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: sa.properties.primaryEndpoints.blob
      }
    }
    
  }
  plan: {
    name: 'rhel-lvm94-gen2'
    product: 'rhel-byos'
    publisher: 'redhat'
  }
}
