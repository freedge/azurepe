@description('Location for all resources.')
param location string = resourceGroup().location

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
param adminKey string
param adminUsername string = 'cloud-user'

param mytags object = {}
var suffix = replace(resourceGroup().name, '-', '')
var saName = 'sto${suffix}'

resource vnetfw 'Microsoft.Network/virtualNetworks@2024-10-01' existing = {
  name: 'vnetfw'
}

resource subnetfw 'Microsoft.Network/virtualNetworks/subnets@2024-10-01' existing = {
  parent: vnetfw
  name: 'subnetfw'
}

resource subnetfwmgmt 'Microsoft.Network/virtualNetworks/subnets@2024-10-01' = {
  parent: vnetfw
  name: 'subnetfwmgmt'
  properties: {
    addressPrefixes: [
      '192.168.2.0/24'
    ]
    privateEndpointNetworkPolicies: 'Enabled'
  }
}

resource lb 'Microsoft.Network/loadBalancers@2024-10-01' existing = {
  name: 'lb'
}

resource sa 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: saName
}

resource autoShutdownConfig 'Microsoft.DevTestLab/schedules@2018-09-15' =  {
  name: 'shutdown-computevm-pan'
  tags: mytags
  location: location
  properties: {
    status: 'Enabled'

    dailyRecurrence: {
      time: '02:00'
    }
    timeZoneId: 'UTC'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: pan.id
  }
}

resource pan 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: 'pan'
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
      vmSize: 'Standard_D4s_v5'
      vmSizeProperties: {
        vCPUsPerCore: 1
      }
    }

    networkProfile: {
      networkApiVersion: '2022-11-01'
      networkInterfaceConfigurations: [
        {
          name: 'mgmt'
          tags: mytags
          properties: {
            primary: true
            enableAcceleratedNetworking: false
            enableIPForwarding: false
            ipConfigurations: [
              {
                name: 'mgmt'
                properties: {
                  subnet: {
                    id: subnetfwmgmt.id
                  }
                  primary: true
                }
              }
            ]
          }
        }
        {
          name: 'priv'
          tags: mytags
          properties: {
            primary: false
            enableAcceleratedNetworking: true
            enableIPForwarding: true
            ipConfigurations: [
              {
                name: 'priv'
                properties: {
                  subnet: {
                    id: subnetfw.id
                  }
                  primary: false
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
      ]
    }

    storageProfile: {
      imageReference: {
        offer: 'vmseries-flex'
        publisher: 'paloaltonetworks'
        sku: 'byol'
        version: '11.2.8'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        osType: 'Linux'
        name: 'pan_os_root_11' // renamed after swap
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: 'pan'
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
      // customData: loadFileAsBase64('cloudinit_rhel_fw.yaml')
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: sa.properties.primaryEndpoints.blob
      }
    }
  }

  // az vm image terms accept --urn paloaltonetworks:vmseries-flex:byol:11.2.5
  plan: {
    name: 'byol'
    publisher: 'paloaltonetworks'
    product: 'vmseries-flex'
  }
}
