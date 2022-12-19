@description('Use Alphanumerics and can\'t use spaces, control characters, or these characters: ~ ! @ # $ % ^ & * ( ) = + _ [ ] { } \'\\\'\' | ; : . \' , < > / ?')
param suffixName string
param location string = resourceGroup().location
param adminUsername string = 'sqladmin'

var migrationServiceName = 'PoCMigrationService'
//var location = resourceGroup().location
var sqlVMName = 'sqlvm-001'
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
var VnetName = 'vnet-${suffixName}'
var InterfaceName = '${sqlVMName}-nic'
var vnetAddressPrefix = '10.0.0.0/16'
var subnet1Prefix = '10.0.0.0/24'
var subnet1Name = 'default'
var IpAddressName = '${sqlVMName}-publicip-${uniqueString(sqlVMName)}'
var publicIpAddressType = 'Dynamic'
var publicIpAddressSku = 'Basic'
var NSGName = '${sqlVMName}-nsg'
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
var sqlAdministratorLogin = 'sqladmin'
var sqlAdministratorLoginPassword = 'My$upp3r$ecret'
var sqlServer_name = 'sqldb-${suffixName}'
var database_name = '${sqlServer_name}/AdventureWorks'
var privateEndpoint_name = 'myPrivateEndpoint'
var privateDnsZone_name = 'privatelink${environment().suffixes.sqlServerHostname}'
var pvtEndpointDnsGroup_name = '${privateEndpoint_name}/mydnsgroupname'
var jbVMName = 'jb-migration'
var jbInterfaceName = 'jumpbox-migration-nic'
var jbNSGName = 'jumpbox-migration-nsg'
var jbIpAddressName = 'jumpbox-migration-ip'
var jbVNetName = 'jumpbox-migration-vnet'

resource dmsName 'Microsoft.DataMigration/sqlMigrationServices@2022-03-30-preview' = {
  name: migrationServiceName
  location: location
  properties: {
  }
}

resource sqlServerName 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServer_name
  location: location
  tags: {
    displayName: sqlServer_name
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
    publicNetworkAccess: 'Disabled'
  }
}

resource databaseName 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: database_name
  location: location
  sku: {
    name: 'S2'
    tier: 'Standard'
    capacity: 50
  }
  tags: {
    displayName: database_name
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
  dependsOn:[sqlServerName]
}

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: IpAddressName
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: NSGName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualNetworksName 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: VnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: InterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${virtualNetworksName.id}/subnets/${subnet1Name}'
          }
          publicIPAddress: {
            id: publicIpAddressName.id
          }
        }
      }
    ]
    enableAcceleratedNetworking: true
  }

}

resource privateEndpointName 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: privateEndpoint_name
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, subnet1Name)
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpoint_name
        properties: {
          privateLinkServiceId: sqlServerName.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneName 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZone_name
  location: 'global'
  properties: {
  }
}

resource privateDnsZoneName_privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneName
  name: '${privateDnsZone_name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworksName.id
    }
  }
}

resource privateDnsZoneName_jbVirtualNetworkName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneName
  name: '${jbVNetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: jbVirtualNetworkName.id
    }
  }
}

resource pvtEndpointDnsGroupName 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: pvtEndpointDnsGroup_name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneName.id
        }
      }
    ]
  }
  dependsOn: [privateEndpointName]
}

resource virtualMachineName 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: sqlVMName
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
          id: networkInterfaceName.id
        }
      ]
    }
    osProfile: {
      computerName: sqlVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}

resource virtualMachineName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  parent: virtualMachineName
  name: 'CustomScriptExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/microsoft/SQL-Migration-AzureSQL-PoC/main/deploy/PostInstallation.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File PostInstallation.ps1'
    }
    protectedSettings: {
    }
  }
}

resource SqlVirtualMachine 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2022-07-01-preview' = {
  name: sqlVMName
  location: location
  properties: {
    virtualMachineResourceId: virtualMachineName.id
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

resource jbPublicIpAddressName 'Microsoft.Network/publicIpAddresses@2019-06-01' = {
  name: jbIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource jbNetworkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: jbNSGName
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

resource jbNetworkInterfaceName 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: jbInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', jbVNetName, 'default')
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jbPublicIpAddressName.id
          }
        }
      }
    ]
  }
}

resource jbVirtualNetworkName 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: jbVNetName
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
            id: jbNetworkSecurityGroupName.id
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

resource jbVirtualMachineName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: jbVMName
  location: location
  properties: {
    osProfile: {
      computerName: jbVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_B2s'
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
        offer: 'Windows-10'
        sku: 'win10-21h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jbNetworkInterfaceName.id
        }
      ]
    }
  }
}

resource JBvirtualMachineName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: jbVirtualMachineName
  name: 'CustomScriptExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/tiagobalabuch/SQL-Migration-AzureSQL-PoC/main/AzureSQLDB/deploy/JumpBoxPostInstallationAzSQLDB.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File JumpBoxPostInstallationAzSQLDB.ps1'
    }
    protectedSettings: {
    }
  }
}

resource jbVirtualNetworkName_peeringTo_virtualNetworksName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  parent: jbVirtualNetworkName
  name: 'peeringTo${VnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworksName.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        VnetName
      ]
    }
  }
}

resource virtualNetworksName_peeringTo_jbVirtualNetworkName 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  parent: virtualNetworksName
  name: 'peeringTo${jbVNetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: jbVirtualNetworkName.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
  }
}
