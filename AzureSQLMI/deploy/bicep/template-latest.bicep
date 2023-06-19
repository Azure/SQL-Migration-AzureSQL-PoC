@description('Use Alphanumerics and can\'t use spaces, control characters, or these characters: ~ ! @ # $ % ^ & * ( ) = + _ [ ] { } \'\\\'\' | ; : . \' , < > / ?')
param suffixName string
param location string = resourceGroup().location
param adminUsername string = 'sqladmin'
param SQLMIAdministratorLogin string = 'sqladmin'

var storageAccountName = toLower('storage${suffixName}')
var dmsName = 'PoCMigrationService'
//var location = resourceGroup().location
var virtualMachineName = 'sqlvm-001'
var virtualMachineSize = 'Standard_D8s_v3'
var imageOffer = 'sql2019-ws2019'
var sqlSku = 'SQLDEV'
var storageWorkloadType = 'General'
var sqlDataDisksCount = 1
var dataPath = 'F:\\SQLData'
var sqlLogDisksCount = 1
var logPath = 'G:\\SQLLog'
//var adminUsername = 'sqladmin'
var adminPassword = 'My$upp3r$ecret'
var diskConfigurationType = 'NEW'
var dataDisksLuns = array(range(0, sqlDataDisksCount))
var logDisksLuns = array(range(sqlDataDisksCount, sqlLogDisksCount))
var dataDisks = {
  createOption: 'Empty'
  caching: 'ReadOnly'
  writeAcceleratorEnabled: false
  storageAccountType: 'Premium_LRS'
  diskSizeGB: 1023
}
var tempDbPath = 'D:\\SQLTemp'
var virtualNetworksName = 'vnet-${suffixName}'
var networkInterfaceName = '${virtualMachineName}-nic'
var networkSecurityGroupName = '${virtualMachineName}-nsg'
var networkSecurityGroupRules = [
  {
    name: 'RDP'
    properties: {
      priority: 300
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
  {
    name: 'AllowAnyMS_SQLInbound'
    properties: {
      protocol: 'TCP'
      sourcePortRange: '*'
      destinationPortRange: '1433'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 310
      direction: 'Inbound'
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
]
var publicIpAddressName = '${virtualMachineName}-publicip-${uniqueString(virtualMachineName)}'
var publicIpAddressType = 'Dynamic'
var publicIpAddressSku = 'Basic'
var SQLMIName = ((length(toLower('sqlmi-${suffixName}')) >= 60) ? substring(toLower('sqlmi-${toLower('sqlmi-${suffixName}')}'), 0, 60) : toLower('sqlmi-${suffixName}'))
// var SQLMIAdministratorLogin = 'sqladmin'
var SQLMIAdministratorLoginPassword = 'My$upp3r$ecret'
var SQLMIVirtualNetworkName = 'vnet-sqlmi'
var SQLMIAddressPrefix = '10.0.0.0/16'
var SQLMISubnetName = 'ManagedInstance'
var SQLMISubnetPrefix = '10.0.0.0/24'
var SQLMIskuName = 'GP_Gen5'
var SQLMIvCores = 8
var SQLMIStorageSizeInGB = 256
var SQLMILicenseType = 'LicenseIncluded'
var SQLMINetworkSecurityGroupName = 'sqlmi-${suffixName}-nsg'
var SQLMIRouteTableName = 'sqlmi-${suffixName}-route-table'
var jbVirtualMachineName = 'jb-migration'
var jbNetworkInterfaceName = 'jb-migration-nic'
var jbNetworkSecurityGroupName = 'jb-migration-nsg'
var jbPublicIpAddressName = 'jb-migration-ip'
var jbVirtualNetworksName = 'vnet-jb-migration'
var SQLMIManagementSubnetName = 'management'
var SQLMIManagementSubnetPrefix = '10.0.1.0/24'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource storageAccountName_default_migration 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${storageAccountName}/default/migration'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    storageAccount
  ]
}

resource dms 'Microsoft.DataMigration/sqlMigrationServices@2022-03-30-preview' = {
  name: dmsName
  location: location
  properties: {
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualNetworks 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworksName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworksName, 'default')
          }
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
  dependsOn: [

    virtualNetworks
  ]
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      dataDisks: [for j in range(0, length(range(0, (sqlDataDisksCount + sqlLogDisksCount)))): {
        lun: range(0, (sqlDataDisksCount + sqlLogDisksCount))[j]
        createOption: dataDisks.createOption
        caching: ((range(0, (sqlDataDisksCount + sqlLogDisksCount))[j] >= sqlDataDisksCount) ? 'None' : dataDisks.caching)
        writeAcceleratorEnabled: dataDisks.writeAcceleratorEnabled
        diskSizeGB: dataDisks.diskSizeGB
        managedDisk: {
          storageAccountType: dataDisks.storageAccountType
        }
      }]
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftSQLServer'
        offer: imageOffer
        sku: sqlSku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}

resource virtualMachineName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/SQL-Migration-AzureSQL-PoC/main/script/SQLVMPostInstallation.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File SQLVMPostInstallation.ps1'
    }
    protectedSettings: {
    }
  }
}

resource Microsoft_SqlVirtualMachine_sqlVirtualMachines_virtualMachine 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2021-11-01-preview' = {
  name: virtualMachineName
  location: location
  properties: {
    virtualMachineResourceId: virtualMachine.id
    sqlManagement: 'Full'
    sqlServerLicenseType: 'PAYG'
    storageConfigurationSettings: {
      diskConfigurationType: diskConfigurationType
      storageWorkloadType: storageWorkloadType
      sqlDataSettings: {
        luns: dataDisksLuns
        defaultFilePath: dataPath
      }
      sqlLogSettings: {
        luns: logDisksLuns
        defaultFilePath: logPath
      }
      sqlTempDbSettings: {
        defaultFilePath: tempDbPath
      }
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: 'PUBLIC'
        port: 1433
        sqlAuthUpdateUserName: adminUsername
        sqlAuthUpdatePassword: adminPassword
      }
    }
  }
}

resource SQLMINetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: SQLMINetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'public_endpoint_inbound'
        properties: {
          description: 'Allow public endpoint inbound traffic'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3342'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1300
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource SQLMIRouteTable 'Microsoft.Network/routeTables@2021-08-01' = {
  name: SQLMIRouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource SQLMIVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: SQLMIVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        SQLMIAddressPrefix
      ]
    }
    subnets: [
      {
        name: SQLMISubnetName
        properties: {
          addressPrefix: SQLMISubnetPrefix
          routeTable: {
            id: SQLMIRouteTable.id
          }
          networkSecurityGroup: {
            id: SQLMINetworkSecurityGroup.id
          }
          delegations: [
            {
              name: 'managedInstanceDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
      {
        name: SQLMIManagementSubnetName
        properties: {
          addressPrefix: SQLMIManagementSubnetPrefix
          networkSecurityGroup: {
            id: SQLMINetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource SQLMI 'Microsoft.Sql/managedInstances@2021-11-01-preview' = {
  name: SQLMIName
  location: location
  sku: {
    name: SQLMIskuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: SQLMIAdministratorLogin
    administratorLoginPassword: SQLMIAdministratorLoginPassword
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', SQLMIVirtualNetworkName, SQLMISubnetName)
    storageSizeInGB: SQLMIStorageSizeInGB
    vCores: SQLMIvCores
    licenseType: SQLMILicenseType
    publicDataEndpointEnabled: true
    minimalTlsVersion: '1.2'
  }
  dependsOn: [
    SQLMIVirtualNetwork
  ]
}

resource jbPublicIpAddress 'Microsoft.Network/publicIpAddresses@2019-06-01' = {
  name: jbPublicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource jbNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: jbNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource jbVirtualNetworks 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: jbVirtualNetworksName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.2.0.0/24'
          networkSecurityGroup: {
            id: jbNetworkSecurityGroup.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource jbVirtualNetworksName_peeringTo_SQLMIVirtualNetwork 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: jbVirtualNetworks
  name: 'peeringTo${SQLMIVirtualNetworkName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: SQLMIVirtualNetwork.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        SQLMIAddressPrefix
      ]
    }
  }

}

resource SQLMIVirtualNetworkName_peeringTo_jbVirtualNetworks 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: SQLMIVirtualNetwork
  name: 'peeringTo${jbVirtualNetworksName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: jbVirtualNetworks.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
  }
}

resource jbVirtualNetworksName_peeringTo_virtualNetworks 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: jbVirtualNetworks
  name: 'peeringTo${virtualNetworksName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworks.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
}

resource virtualNetworksName_peeringTo_jbVirtualNetworks 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: virtualNetworks
  name: 'peeringTo${jbVirtualNetworksName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: jbVirtualNetworks.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
  }
}

resource jbNetworkInterface 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: jbNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', jbVirtualNetworksName, 'default')
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jbPublicIpAddress.id
          }
        }
      }
    ]
  }
  dependsOn: [
    jbVirtualNetworks

  ]
}

resource jbVirtualMachine 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: jbVirtualMachineName
  location: location
  properties: {
    osProfile: {
      computerName: jbVirtualMachineName
      adminUsername: SQLMIAdministratorLogin
      adminPassword: SQLMIAdministratorLoginPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_B4ms'
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jbNetworkInterface.id
        }
      ]
    }
  }
}

resource JBvirtualMachineName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: jbVirtualMachine
  name: 'CustomScriptExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/SQL-Migration-AzureSQL-PoC/main/script/JumpBoxPostInstallation.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File JumpBoxPostInstallation.ps1'
    }
    protectedSettings: {
    }
  }
}
