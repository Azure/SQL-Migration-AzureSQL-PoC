# Online migration for Azure SQL Managed Instance using File Share using CLI

Perform offline migrations of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Database using the Azure SQL Migration extension.

### Prerequisites

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 *(Already installed)*
- Azure CLI *(Already installed)*
- Az datamigration extension
- Azure storage account *(Already provisioned)*
- Azure Data Studio *(Already installed)*
- Azure SQL Migration extension for Azure Data Studio

## Getting Started

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

Open a [Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=us). It is already installed in the VM and by default it uses PowerShell.

1. Install az datamigration extension if it isn't installed.

    ```azurecli
    az extension add --name datamigration
    ```

2. Run the following to log in from your client using your default web browser

    ```azurecli
    az login
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```azurecli
    az account set --subscription <subscription-id>
    ```

    The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

    In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

3. Backup database

    ```sql
    USE master
    BACKUP DATABASE AdventureWorks2019 TO Disk = 'C:\temp\backup\AdventureWorks2019.bak'
    WITH CHECKSUM
    ```

### Register Database Migration Service with self-hosted Integration Runtime

1. Use the **az datamigration sql-service list-auth-key** command to obtain AuthKeys.

    ```azurecli
    $AuthKey = az datamigration sql-service list-auth-key `
    --resource-group "<resource group name>" `
    --sql-migration-service-name "PoCMigrationService" `
    --query "authKey1"
    ```

    - The following example obtains the authKey:

    ```azurecli
    $AuthKey = az datamigration sql-service list-auth-key `
    --resource-group "oneclickpoc" `
    --sql-migration-service-name "PoCMigrationService" `
    --query "authKey1"
    ```

2. Change the PowerShell execution policy.

    ```azurecli
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

3. Use the **az datamigration register-integration-runtime** command to register the service on Integration Runtime.

    ```azurecli
    az datamigration register-integration-runtime --auth-key <authKey>
    ```

    The following example registers the service on Integration Runtime:

    ```azurecli
    az datamigration register-integration-runtime --auth-key $AuthKey
    ```

    > [!WARNING]
    >
    > If you receive an error message saying: "RegisterIntegrationRuntime.ps1 cannot be loaded because running scripts is disabled on this system", please, run the following command and re-run the az command above.
    >
    > `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

### Start database migration

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

Use the **az datamigration sql-managed-instance create** command to create and start a database migration.
    ```azurecli
    az datamigration sql-managed-instance create `
    --source-location '{\"fileShare\":{\"path\":\"\\\\10.1.0.4\\SQLBackup\",\"password\":\"My$upp3r$ecret\",\"username\":\"10.1.0.4\\sqladmin\"}}' `
    --target-location account-key="<storage key>" storage-account-resource-id="/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>" `
    --migration-service "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.DataMigration/SqlMigrationServices/PoCMigrationService" `
    --scope "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Sql/managedInstances/<azure sql mi instance name>" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.1.0.4" encrypt-connection=true trust-server-certificate=true password="My`$upp3r`$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks" `
    --resource-group sqladmin `
    --managed-instance-name <azure sql mi instance name> `

    The following example creates and starts a migration of complete source database with target database name AdventureWorks:

    ```azurecli

    az datamigration sql-managed-instance create `
    --source-location '{\"fileShare\":{\"path\":\"\\\\10.1.0.4\\SQLBackup\",\"password\":\"My`$upp3r`$ecret\",\"username\":\"10.1.0.4\\sqladmin\"}}' `
    --target-location account-key="XXXXXXXX" storage-account-resource-id="/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Storage/storageAccounts/<storage account name>" `
    --migration-service "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.DataMigration/SqlMigrationServices/PoCMigrationService" `
    --scope "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Sql/managedInstances/sqlmicsapocmigration" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.1.0.4" encrypt-connection=true trust-server-certificate=true password="My`$upp3r`$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks" `
    --resource-group sqladmin `
    --managed-instance-name sqlmicsapocmigration `
    ```

> [!TIP]
>
> You should take all necessary backups.

Learn more about using [CLI to migrate](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-to-sql-mi-blob.md#start-online-database-migration)

### Monitoring migration

Use the **az datamigration sql-db show** command to monitor migration.

1. Basic migration details

    ```azurecli
    az datamigration sql-managed-instance show --managed-instance-name "<azure sql mi instance name>" --resource-group "<resource group name>" --target-db-name "AdventureWorks"
    ```

2. Gets complete migration detail

    ```azurecli
    az datamigration sql-managed-instance show --managed-instance-name "<azure sql mi instance name>" --resource-group "<resource group name>" --target-db-name "AdventureWorks" --expand=MigrationStatusDetails
    ```

3. *ProvisioningState* should be "**Creating**", "**Failed**" or "**Succeeded**"

    ```azurecli
    az datamigration sql-managed-instance show --managed-instance-name "<azure sql mi instance name>" --resource-group "<resource group name>" --target-db-name "AdventureWorks" --expand=MigrationStatusDetails --query "properties.provisioningState"
    ```

4. *MigrationStatus* should be "**InProgress**", "**Canceling**", "**Failed**" or "**Succeeded**"

    ```azurecli
    az datamigration sql-managed-instance show --managed-instance-name "<azure sql mi instance name>" --resource-group "<resource group name>" --target-db-name "AdventureWorks" --expand=MigrationStatusDetails --query "properties.migrationStatus"
    ```

## Migrating at scale

This script performs an [end to end migration of multiple databases in multiple servers](https://github.com/Azure-Samples/data-migration-sql/tree/main/CLI/scripts/multiple%20databases)

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
