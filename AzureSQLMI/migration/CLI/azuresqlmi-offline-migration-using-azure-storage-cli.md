# Offline migration for Azure SQL Managed Instance using Azure Storage using CLI

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

    Backups must be taken before starting the migration:
    - [Create SAS tokens for your storage containers](https://learn.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens?tabs=Containers)
    - [Create a SQL Server credential using a shared access signature](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-use-azure-blob-storage-service-with-sql-server-2016?view=sql-server-ver16#2---create-a-sql-server-credential-using-a-shared-access-signature)
    - [Database backup to URL](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-use-azure-blob-storage-service-with-sql-server-2016?view=sql-server-ver16#3---database-backup-to-url)

    The following T-SQL is an example that creates the credential to use a Shared Access Signature and creates a backup.

    ```sql
    USE master
    CREATE CREDENTIAL [https://storagemigration.blob.core.windows.net/migration] 
      -- this name must match the container path, start with https and must not contain a forward slash at the end
    WITH IDENTITY='SHARED ACCESS SIGNATURE' 
      -- this is a mandatory string and should not be changed   
     , SECRET = 'XXXXXXX' 
       -- this is the shared access signature key. Don't forget to remove the first character "?"   
    GO
    
    -- Back up the full AdventureWorks2019 database to the container
    BACKUP DATABASE AdventureWorks2019 TO URL = 'https://storagemigration.blob.core.windows.net/migration/AdventureWorks2019.bak'
    WITH CHECKSUM
    ```

### Start database migration

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

Use the **az datamigration sql-managed-instance create** command to create and start a database migration.

    ```azurecli
    az datamigration sql-managed-instance create `
    --source-location '{\"AzureBlob\":{\"storageAccountResourceId\":\"/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>\",\"accountKey\":\"<storage key>\",\"blobContainerName\":\"migration\"}}' `
    --migration-service "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.DataMigration/SqlMigrationServices/MySqlMigrationService" `
    --scope "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Sql/managedInstances/<azure sql mi instance name>" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.1.0.4" password="My$upp3r$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks" `
    --resource-group <resource group name> `
    --managed-instance-name <azure sql mi instance name>
    --offline-configuration last-backup-name="<backup name>.bak" offline=true
    ```
     
     The following example creates and starts a migration of complete source database with target database name AdventureWorks:

    ```azurecli
    az datamigration sql-managed-instance create `
    --source-location '{\"AzureBlob\":{\"storageAccountResourceId\":\"/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Storage/storageAccounts/storagepocmigration\",\"accountKey\":\"XXXXXX\",\"blobContainerName\":\"migration\"}}' `
    --migration-service "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.DataMigration/SqlMigrationServices/MySqlMigrationService" `
    --scope "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Sql/managedInstances/sqlmicsapocmigration" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.1.0.4" password="My$upp3r$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks" `
    --resource-group oneclickpoc `
    --managed-instance-name sqlmicsapocmigration
    --offline-configuration last-backup-name="AdventureWorks2019.bak" offline=true
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
