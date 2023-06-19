# Deploy the solution for Azure SQL Managed Instance

In this section, you will provision all Azure resources required to complete this PoC.

## Deployment options

| Deployment language |                                                                                                     |
| :-------------------------------: | :----------------------------------------------------------------------------------:  |
|[**ARM**](#azure-resource-manager) | [![azure resource manager](../../media/ARM-Deployment.svg)](#azure-resource-manager)  |
|[**Bicep**](#bicep)                | [![bicep](../../media/Bicep-Logo.svg)](#bicep)                                        |
|[**Terraform**](#terraform)        | [![terraform](../../media/Terraform-Logo.svg)](#terraform)                            |

## Deployment diagram

![resource-visualizer](/media/sqlmi-resource-visualizer.png)

## Azure Resource Manager

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FSQL-Migration-AzureSQL-PoC%2Fmain%2FAzureSQLMI%2Fdeploy%2Farm%2Ftemplate-latest.json)

The [ARM template (template-latest.json)](arm/template-latest.json) is used to provision Azure resources in a resource group.

Right-click or `Ctrl + click` the button below to open the Azure Portal in a new window. This will redirect you to the Custom Deployment wizard in the Azure Portal.

Select the Azure subscription and the resource group that you would like to use for this PoC.

## Bicep

The [Bicep template (template-latest.bicep)](bicep/template-latest.bicep) is used to provision Azure resources in a resource group.

 [Learn more about bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep).

### Prerequisites

- [Install Bicep tools](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### How to deploy it

1. Run the following to log in from your client using your default web browser

    ```azurecli
    az login
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```azurecli
    az account set --subscription <subscription-id>
    ```

2. Find a location you want to deploy the resource group
  
    ```azurecli
    az account list-locations -o table
    ```

3. Create a resource group

    ```azurecli
    az group create --location "<location>" --name "<resource group name>"
    ```

    The following example deploys a resource group in North Europe

    ```azurecli
    az group create --location "northeurope" --name "one-click-poc"
    ```

4. Deploy a bicep template

    ```azurecli
    az deployment group create --resource-group "<resource group name>" --template-file C:\temp\bicep\template-latest.bicep

    ```

    The following example deploys a bicep template

    ```azurecli
    az deployment group create --resource-group "one-click-poc" --template-file C:\temp\bicep\template-latest.bicep
    ```

## Terraform

The [Terraform template (terraform/template-latest.tf)](terraform/template-latest.tf) is used to provision Azure resources in a resource group.

 [Learn more about Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/overview).

Prerequisites

- [Install Terraform](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

1. Run the following to log in from your client using your default web browser

    ```azurecli
    az login
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```azurecli
    az account set --subscription <subscription-id>
    ```

2. Find a location you want to deploy the resource group
  
    ```azurecli
    az account list-locations -o table
    ```

3. Move to the folder [AzureSQLMI/deploy/terraform](AzureSQLMI/deploy/terraform)

    ```azurecli
    cd AzureSQLMI/deploy/terraform
    ```

4. Open the file [terraform.tfvars](terraform/terraform.tfvars) and provide values for the variables `resource_group_name` and `resource_group_location`

    e.g:

    ```azurecli
    resource_group_name = "one-click-poc"
    resource_group_location = "westeurope"
    ```

5. Initialize a working directory for the terraform configuration

    ```azurecli
    terraform init
    ```

6. Deploy the terraform template

    ```azurecli
    terraform apply -auto-approve
    ```

    A message asking for input of a value for the variable `suffix` will be displayed

    ```azurecli
    var.suffix
        Enter a value: 
    ```

    Insert a value and press Enter.

## Azure Resources

The template provisions the following resources in the Azure subscription

- Azure Resource Group
- Azure Storage Account
- Azure SQL Managed Instance
- VNet for Azure SQL Managed Instance
- NSG for Azure SQL Managed Instance
- Virtual network traffic routing
- Azure SQL VM
- Network interface for Azure SQL VM
- VNet for Azure SQL VM
- Public IP for Azure SQL VM
- NSG for Azure SQL VM
- JumpBox VM
- Network interface for JumpBox VM
- VNet for JumpBox VM
- NSG for JumpBox VM
- Public IP for JumpBox VM
- Virtual network peering

> [!IMPORTANT]
> Please note that it takes 6 to 8 hours approximately to provision all these resources in an Azure subscription.

Some of the Azure services provisioned require a globally unique name and a “suffix” has been added to their names to ensure uniqueness.

| Azure Service              | Name             | Pricing Tier      | How to    |
|:----                       |:-----            | :----             |:-----     |
| Resource Group             | one-click-PoC    |                   | [Create a Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)
| Storage Account            | storage*suffix*  |                   |[Create a storage account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal)|
| SQL Server on Azure VM     | sqlvm-001   | Standard_D8s_v3   |[Provision SQL Server on Azure VM](https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/create-sql-vm-portal?view=azuresql) |
| Azure SQL Managed Instance | sqlmi-*suffix*   | GP_Gen5 8vCore    |[Create an Azure SQL Managed Instance](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/instance-create-quickstart?view=azuresql)|
| Azure VM                  | jb-migration      | Standard_B4ms     |[Create a Windows virtual machine](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-portal) |

### Credential

|                       | Admin User Name   | Password         |
|:----                  |:-----             | :----            |
| SQL VM                | sqladmin          | My\$upp3r\$ecret |
| Azure SQL Database    | sqladmin          | My\$upp3r\$ecret |
| JumpBox VM            | sqladmin          | My\$upp3r\$ecret |

## Page Navigator

- [SQL Server migration one-click PoC to Azure SQL](../../../README.md)
  
- [One-click PoC to Azure SQL DB](../../../AzureSQLDB/deploy/README.md)
  - ***Assessment and SKU recommendation***
    - [CLI](../../../AzureSQLDB/assessment/CLI/azuresqldb-assessment-sku-using-cli.md)
    - [PowerShell](../../../AzureSQLDB/assessment/PowerShell/azuresqldb-assessment-sku-using-ps.md)
  - ***Offline migration***
    - [CLI](../../../AzureSQLDB/migration/CLI/azuresqldb-offline-migration-using-cli.md)
    - [PowerShell](../../../AzureSQLDB/migration/PowerShell/azuresqldb-offline-migration-using-ps.md)
  
- [One-click PoC to Azure SQL MI](../../../AzureSQLMI/deploy/README.md)
  - ***Assessment and SKU recommendation***
    - [CLI](../../../AzureSQLMI/assessment/CLI/azuresqlmi-assessment-sku-using-cli.md)
    - [PowerShell](../../../AzureSQLMI/assessment/PowerShell/azuresqlmi-assessment-sku-using-ps.md)
  - ***Offline migration using Storage Account***
    - [CLI](../../../AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-azure-storage-cli.md)
    - [PowerShell](../../../AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-azure-storage-ps.md)
  - ***Offline migration using File Share***
    - [CLI](../../../AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-file-share-cli.md)
    - [PowerShell](../../../AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-file-share-ps.md)
  - ***Online migration using Storage Account***
    - [CLI](../../../AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-azure-storage-cli.md)
    - [PowerShell](../../../AzureSQLMI/migration/PowerShell/azuresqlmi-online-migration-using-azure-storage-ps.md)
  - ***Online migration using File Share***
    - [CLI](../../../AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-file-share-cli.md)
    - [PowerShell](../../../AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-file-share-ps.md)
  - ***Login migration***
    - [CLI](../../../AzureSQLMI/migration/CLI/azuresqlmi-login-migration-using-cli.md)
    - [PowerShell](../../../AzureSQLMI/migration/PowerShell/azuresqlmi-login-migration-using-ps.md)
