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

variable "sql_mi_administrator_login" {
  type = string
}

variable "storage_workload_type" {
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
variable "sql_vm_name" {
  type = string
}
variable "virtual_machine_name" {
  type = string
}
variable "virtual_machine_size" {
  type = string
}
variable "image_offer" {
  type = string
}
variable "sql_sku" {
  type = string
}
variable "sql_data_disk_count" {
  type = number
}

variable "data_path" {
  type = string
}

variable "sql_log_disk_count" {
  type = number
}

variable "log_path" {
  type = string
}

variable "disk_configuration_type" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

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

variable "jb_vm_name" {
  type = string
}

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

variable "sql_mi_administratorloginpassword" {
  type = string
}
variable "sql_mi_virtualnetworkname" {
  type = string
}
variable "sql_mi_address_prefix" {
  type = string
}
variable "sql_mi_subnetname" {
  type = string
}
variable "sql_mi_subnet_prefix" {
  type = string
}
variable "sql_mi_sku_name" {
  type = string
}
variable "sql_mi_vcores" {
  type = number
}
variable "sql_mi_storage_size_in_gb" {
  type = number
}
variable "sql_mi_license_type" {
  type = string
}

variable "sql_mi_management_subnet_name" {
  type = string
}
variable "sql_mi_management_subnet_prefix" {
  type = string
}
