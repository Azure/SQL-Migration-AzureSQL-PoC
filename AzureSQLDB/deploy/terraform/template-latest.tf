terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "=1.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azapi" {
  default_location = var.resource_group_location
}

provider "azurerm" {
  features {}
}

locals {
  total_disk_count = var.sql_log_disk_count + var.sql_data_disk_count
  data_disks_luns  = [for i in range(0, var.sql_data_disk_count) : i]
  log_disks_luns   = [for i in range(var.sql_data_disk_count, var.sql_data_disk_count + var.sql_log_disk_count) : i]
}

resource "random_id" "random_deployment_suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "${var.sql_server_name}-${var.suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_administrator_login
  administrator_login_password = var.sql_administrator_login_password

  tags = {
    displayName = "${var.sql_server_name}-${var.suffix}"
  }
}

resource "azurerm_mssql_database" "mssql_database" {
  name        = var.database_name
  server_id   = azurerm_mssql_server.sqlserver.id
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = 50
  read_scale  = false
  sku_name    = "S2"
  tags = {
    displayName = var.database_name
  }
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.sql_vm_name}-publicip-${random_id.random_deployment_suffix.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  allocation_method   = var.public_ip_address_type
  sku                 = var.public_ip_address_sku
}

resource "azapi_resource" "dms" {
  type = "Microsoft.DataMigration/sqlMigrationServices@2022-03-30-preview"
  name = var.migration_service_name
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.sql_vm_name}-nsg"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_rule" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_any_ms_sql_inbound_rule" {
  name                        = "AllowAnyMS_SQLInbound"
  priority                    = 310
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.suffix}"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_prefix]

  subnet {
    name           = var.subnet1_name
    address_prefix = var.subnet1_prefix
    security_group = azurerm_network_security_group.nsg.id
  }
}

resource "azurerm_network_interface" "network_interface" {
  name                = "${var.sql_vm_name}-nic"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_virtual_network.vnet.id}/subnets/${var.subnet1_name}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.publicip.id
    private_ip_address            = "10.0.0.4"
  }
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.private_endpoint_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = "${azurerm_virtual_network.vnet.id}/subnets/${var.subnet1_name}"
  private_service_connection {
    name                           = var.private_endpoint_name
    private_connection_resource_id = azurerm_mssql_server.sqlserver.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "myPrivateEndpoint_mydnsgroupname"
    private_dns_zone_ids = [azurerm_private_dns_zone.pdz.id]
  }

}

resource "azurerm_private_dns_zone" "pdz" {
  name                = "privatelink${azurerm_mssql_server.sqlserver.fully_qualified_domain_name}"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdzvnlink" {
  name                  = "${azurerm_private_dns_zone.pdz.name}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pdz.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "jb_pdzvnlink" {
  name                  = "${var.jb_vnet_name}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pdz.name
  virtual_network_id    = azurerm_virtual_network.jb_vnet.id
}

# Jump box NSG
resource "azurerm_network_security_group" "jb_nsg" {
  name                = var.jb_nsg_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "rdp_jb_rule" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.jb_nsg.name
}

resource "azurerm_virtual_network" "jb_vnet" {
  name                = var.jb_vnet_name
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]


  subnet {
    name           = "default"
    address_prefix = "10.2.0.0/24"
    security_group = azurerm_network_security_group.jb_nsg.id
  }
}
resource "azurerm_public_ip" "jp_publicip" {
  name                = var.jb_ip_address_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "jb_nic" {
  name                = "${var.jb_interface_name}-nic"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_virtual_network.jb_vnet.id}/subnets/default"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jp_publicip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                = var.sql_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  vm_size             = var.virtual_machine_size

  network_interface_ids = [azurerm_network_interface.network_interface.id]

  os_profile {
    computer_name  = var.sql_vm_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  storage_os_disk {
    name              = "osdisk001"
    managed_disk_type = "Premium_LRS"
    create_option     = "FromImage"
  }
  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = var.image_offer
    sku       = var.sql_sku
    version   = "latest"
  }

}

resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
  {
    "fileUris": ["https://raw.githubusercontent.com/Azure/SQL-Migration-AzureSQL-PoC/new-features-3.0/script/SQLVMPostInstallation.ps1"],
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File SQLVMPostInstallation.ps1"
  }
  SETTINGS

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "jb_vm_extension" {
  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.jb_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/Azure/SQL-Migration-AzureSQL-PoC/new-features-3.0/script/JumpBoxPostInstallation.ps1"],
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File JumpBoxPostInstallation.ps1"
    }
  SETTINGS

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
    read   = "60m"
  }
}

resource "azurerm_managed_disk" "data_disk" {
  count                = local.total_disk_count
  name                 = "${var.sql_vm_name}-disk-${count.index}"
  location             = var.resource_group_location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1023
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  count              = local.total_disk_count
  managed_disk_id    = azurerm_managed_disk.data_disk.*.id[count.index]
  virtual_machine_id = azurerm_virtual_machine.vm.id
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_windows_virtual_machine" "jb_vm" {
  name                = var.jb_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  size                = "Standard_B4ms"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.jb_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }
}

resource "azurerm_mssql_virtual_machine" "sql_vm" {
  virtual_machine_id               = azurerm_virtual_machine.vm.id
  sql_license_type                 = "PAYG"
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PUBLIC"
  sql_connectivity_update_password = var.admin_password
  sql_connectivity_update_username = var.admin_username
  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"
    data_settings {
      luns              = local.data_disks_luns
      default_file_path = var.data_path
    }
    log_settings {
      luns              = local.log_disks_luns
      default_file_path = var.log_path
    }
  }
  depends_on = [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment]
}

resource "azurerm_virtual_network_peering" "peering_to_vnet" {
  name                         = "peeringTo${azurerm_virtual_network.vnet.name}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.jb_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

}

resource "azurerm_virtual_network_peering" "peering_to_jb_vnet" {
  name                         = "peeringTo${azurerm_virtual_network.jb_vnet.name}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.jb_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
