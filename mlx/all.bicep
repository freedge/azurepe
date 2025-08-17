@description('Location for all resources.')
param location string = resourceGroup().location

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
param adminKey string
param adminUsername string = 'cloud-user'

@description('The size of the VM')
param vmSize string = 'Standard_D16s_v5'

param mytags object = {}
param saRules array = [{ value: '0.0.0.0/0', action: 'Allow' }]
param nsgRules array = ['0.0.0.0/0']

var suffix = replace(resourceGroup().name, '-', '')
var saName = 'sto${suffix}'

// ignore
param sid string
param nVmss int
param nZone int
param zone int = 3

var zones = [zone]

// https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/windows/serial-console-windows#use-serial-console-with-custom-boot-diagnostics-storage-account-firewall-enabled
var serialConsoleRules = [
  {
    value: '4.210.131.60'
    action: 'Allow'
  }
  {
    value: '20.105.209.72'
    action: 'Allow'
  }
  {
    value: '20.105.209.73'
    action: 'Allow'
  }
  {
    value: '40.113.178.49'
    action: 'Allow'
  }
  {
    value: '52.146.137.65'
    action: 'Allow'
  }
  {
    value: '52.146.139.220'
    action: 'Allow'
  }
  {
    value: '52.146.139.221'
    action: 'Allow'
  }
  {
    value: '98.71.107.78'
    action: 'Allow'
  }
]

// az vm image list --publisher RedHat --offer rhel-byos --sku rhel-lvm95-gen2 --all
// az vm image terms accept --urn RedHat:rhel-byos:rhel-..
var rhelPlan = {
  name: 'rhel-lvm95-gen2'
  product: 'rhel-byos'
  publisher: 'redhat'
}

var rhelImageRef = {
  offer: rhelPlan.product
  publisher: 'RedHat'
  sku: rhelPlan.name
  version: 'latest'
}

resource applyTags 'Microsoft.Resources/tags@2025-03-01' = {
  name: 'default'
  scope: resourceGroup()
  properties: {
    tags: mytags
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  location: location
  name: 'vnet'
  tags: mytags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
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
          addressPrefix: '192.168.0.0/17'
          nextHopIpAddress: '10.0.0.4'
        }
      }
      {
        name: 'myrt2'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '192.168.128.0/17'
          nextHopIpAddress: '10.0.0.5'
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'subnet'
  properties: {
    addressPrefixes: ['10.0.0.0/24']
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable: {
      id: rt.id
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
  }
}

resource spoke1Avset 'Microsoft.Compute/availabilitySets@2024-11-01' existing = {
    name: 'spoke1Avset'
}

resource nic11 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nic11'
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
        name: 'ipconfig111'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.111'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig112'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.112'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig113'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.113'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig114'
        properties: {
          primary: false
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.114'
          privateIPAddressPrefixLength: 24
        }
      }
    ]
  }
}

resource nic12 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  tags: mytags
  name: 'nic12'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
    enableIPForwarding: false
    ipConfigurations: [
      {
        name: 'ipconfig12'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.12'
          privateIPAddressPrefixLength: 24
        }
      }
    ]
  }
}
resource nic13 'Microsoft.Network/networkInterfaces@2024-05-01' = if (false) {
  tags: mytags
  name: 'nic13'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
    enableIPForwarding: false
    auxiliaryMode: 'AcceleratedConnections'
    auxiliarySku: 'A1'
    ipConfigurations: [
      {
        name: 'ipconfig131'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.131'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig132'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: false
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.132'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig133'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: false
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.133'
          privateIPAddressPrefixLength: 24
        }
      }
      {
        name: 'ipconfig134'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: false
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.134'
          privateIPAddressPrefixLength: 24
        }
      }
    ]
  }
}
resource nic14 'Microsoft.Network/networkInterfaces@2024-05-01' = if (false) {
  tags: mytags
  name: 'nic14'
  location: location
  properties: {
    enableAcceleratedNetworking: true
    auxiliaryMode: 'AcceleratedConnections'
    auxiliarySku: 'A1'
    networkSecurityGroup: {
      id: nsg.id
    }
    enableIPForwarding: false
    ipConfigurations: [
      {
        name: 'ipconfig14'
        properties: {
          subnet: {
            id: subnet.id
          }
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.14'
          privateIPAddressPrefixLength: 24
        }
      }
    ]
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2024-05-01' = if (true) {
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
            id: subnet.id
          }
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.5'
          privateIPAddressPrefixLength: 24
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
    dnsSettings: {
      domainNameLabel: 'frigo'
    }
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2024-01-01' = {
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
      ipRules: concat(saRules, serialConsoleRules)
      virtualNetworkRules: [
        {
          id: subnet.id
        }
      ]
    }
  }
}

resource fileser 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  name: 'default'
  parent: sa
}

resource sha 'Microsoft.Storage/storageAccounts/fileServices/shares@2024-01-01' = {
  name: 'sha'
  parent: fileser
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource autoShutdownConfig1 'Microsoft.DevTestLab/schedules@2018-09-15' = if (true) {
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

resource autoShutdownConfig2 'Microsoft.DevTestLab/schedules@2018-09-15' = if (true) {
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

// help us push data to prometheus
resource pro 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  location: location
  name: 'pro'
  tags: mytags
}

resource vm1 'Microsoft.Compute/virtualMachines@2024-11-01' = if (true) {
  name: 'vm1'
  location: location
  tags: mytags
  identity: {
    userAssignedIdentities: {
      '${pro.id}': {}
    }
    type: 'SystemAssigned, UserAssigned'
  }
  zones: zones
  properties: {

    // availabilitySet: {
    //   id: spoke1Avset.id
    // }
    
    hardwareProfile: {
      vmSize: vmSize
    }

    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: false
        vTpmEnabled: true
      }
    }

    storageProfile: {
      // diskControllerType: 'NVMe'
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

      imageReference: rhelImageRef
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic11.id
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
  plan: rhelPlan
}

resource vm2 'Microsoft.Compute/virtualMachines@2024-07-01' = if (true) {
  name: 'vm2'
  location: location
  tags: mytags
  identity: {
    type: 'SystemAssigned'
  }
  zones: ['1']

  properties: {

    // availabilitySet: {
    //    id: spoke1Avset.id
    // }

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
      // diskControllerType: 'NVMe'
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

      imageReference: rhelImageRef
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
  plan: rhelPlan
}

resource lb 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: 'lb'
  tags: mytags
  location: location
  sku:{
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
            id: subnet.id
          }
          privateIPAddress: '10.0.0.33'
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rul'
        properties: {
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb', 'probe')
          }
          protocol:  'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
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
