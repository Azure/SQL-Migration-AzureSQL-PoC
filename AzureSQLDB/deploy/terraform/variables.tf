variable "suffix" {
  type = string
}
variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "migration_service_name" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "sql_administrator_login" {
  type = string
}

variable "sql_administrator_login_password" {
  type = string
}

variable "database_name" {
  type = string
}

variable "public_ip_address_type" {
  type = string
}
variable "public_ip_address_sku" {
  type = string
}
variable "sql_vmname" {
  type = string
}

# variable "virtual_machine_size" {
#   type = string
# }
# variable "image_offer" {
#   type = string
# }
# variable "sql_sku" {
#   type = string
# }
# variable "storage_workload_type" {
#   type = string
# }
# variable "sql_data_disks_count" {
#   type = string
# }
# variable "data_path" {
#   type = string
# }
# variable "sql_log_disks_count" {
#   type = string
# }
# variable "log_path" {
#   type = string
# }
//var adminUsername = 'sqladmin'
# var "admin_password" {
#   type = string
# }
# variable "diskConfigurationType" {
#   type = string
# }
# variable "data_disks_luns"{

# } #= array(range(0, sqlDataDisksCount))
# var logDisksLuns = array(range(sqlDataDisksCount, sqlLogDisksCount))
# var dataDisks = {
#   createOption: 'Empty'
#   caching: 'ReadOnly'
#   writeAcceleratorEnabled: false
#   storageAccountType: 'Premium_LRS'
#   diskSizeGB: 1023
# }
variable "temp_db_path" {
  type = string
}
variable "vnet_address_prefix" {
  type = string
}
variable "subnet1_prefix" {
  type = string
}
variable "subnet1_name" {
  type = string
}

variable "private_endpoint_name" {
  type = string
}
# variable "private_dns_zone_name" {
#   type = string
# }
# variable "pvt_endpoint_dns_group_name" {
#   type = string
# }
# variable "jb_vm_name" {
#   type = string
# }
variable "jb_interface_name" {
  type = string
}
variable "jb_nsg_name" {
  type = string
}
variable "jb_ip_address_name" {
  type = string
}
variable "jb_vnet_name" {
  type = string
}

