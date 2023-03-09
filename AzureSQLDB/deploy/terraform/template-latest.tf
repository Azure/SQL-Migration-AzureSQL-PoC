terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
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
  resource_group_name          = var.resource_group_name
  location                     = var.resource_group_location
  version                      = "12.0"
  administrator_login          = var.sql_administrator_login
  administrator_login_password = var.sql_administrator_login_password

  tags = {
    displayName = "${var.sql_server_name}-${var.suffix}"
  }
}

resource "azurerm_mssql_database" "mssql_database" {
  name         = var.database_name
  server_id    = azurerm_mssql_server.sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  read_scale   = true
  sku_name     = "S2"
  tags = {
    displayName = var.database_name
  }
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.sql_vmname}-publicip-${random_id.random_deployment_suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = var.public_ip_address_type
  sku                 = var.public_ip_address_sku
}

# resource "azurerm_database_migration_service" "dms" {
#   name                = var.migration_service_name
#   location            = var.resource_group_location
#   resource_group_name = var.resource_group_name
# }

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.sql_vmname}-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
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
  resource_group_name         = var.resource_group_name
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
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.suffix}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_prefix]

  subnet {
    name           = var.subnet1_name
    address_prefix = var.subnet1_prefix
    security_group = azurerm_network_security_group.nsg.id
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet1_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet1_prefix]
  }

resource "azurerm_network_interface" "network_interface" {
  name                = "${var.sql_vmname}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_virtual_network.vnet.id}/subnets/${var.subnet1_name}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}



resource "azurerm_private_endpoint" "example" {
  name                = var.private_endpoint_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnet1.id
  private_service_connection {
    name                           = var.private_endpoint_name
    private_connection_resource_id = azurerm_mssql_server.sqlserver.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "pdz" {
    name = "privatelink${var.sql_server_name}"
    resource_group_name = var.resource_group_name
}


resource "azurerm_private_dns_zone_virtual_network_link" "pdzvnlink" {
  name                  = "${azurerm_private_dns_zone.pdz.name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}



resource "azurerm_private_dns_zone_virtual_network_link" "jb_pdzvnlink" {
  name                  = "${var.jb_vnet_name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz.name
  virtual_network_id    = azurerm_virtual_network.jb_vnet.id
}



# Jump box NSG
resource "azurerm_network_security_group" "jb_nsg" {
  name                = var.jb_nsg_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
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
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.jb_nsg.name
}

resource "azurerm_virtual_network" "jb_vnet" {
  name                = var.jb_vnet_name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.2.0.0/16"]
  #security_group = azurerm_network_security_group.jb_nsg.id
}

resource "azurerm_subnet" "jb_subnet" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.jb_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  }

resource "azurerm_public_ip" "jp_publicip" {
  name                = var.jb_ip_address_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "t" {
  name                = "${var.jb_interface_name}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.jb_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jp_publicip.id
  }
}
