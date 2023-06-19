# Offline migration for Azure SQL Managed Instance using Azure Storage using PowerShell

Perform offline migrations of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Database using the Azure SQL Migration extension.

### Prerequisites

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 (Already installed)
- Az.DataMigration PowerShell module

## Getting Started

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

Open a [Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=us). It is already installed in the VM and by default it uses PowerShell.

The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

In addition, the Azure PowerShell command [Az.DataMigration](https://learn.microsoft.com/en-us/powershell/module/az.datamigration/?view=azps-10.0.0) can be used to manage data migration at scale.

1. Run the following to log in from your client using your default web browser if you are not logged in.

    ```powershell
    Connect-AzAccount -Subscription <Subscription-id>
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```powershell
    Set-AzContext -SubscriptionId <subscription-id>
    ```

    The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

    In addition, the PowerShell command [Data Migration](https://learn.microsoft.com/en-us/powershell/module/az.datamigration/?view=azps-10.0.0#data-migrationt) can be used to manage data migration at scale.

2. Backup database

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

1. Convert the passwords to secure string

    ```powershell
    $sourcePassword = ConvertTo-SecureString "My`$upp3r`$ecret" -AsPlainText -Force
    ```

2. Use the **New-AzDataMigrationToSqlManagedInstance** command to create and start a database migration.

    ```powershell
        New-AzDataMigrationToSqlManagedInstance `
        -ResourceGroupName <resource group name> `
        -ManagedInstanceName <azure sql mi instance name> `
        -TargetDbName "AdventureWorks" `
        -Kind "SqlMI" `
        -Scope "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Sql/managedInstances/<azure sql mi instance name>" `
        -MigrationService "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.DataMigration/SqlMigrationServices/PoCMigrationService" `
        -AzureBlobStorageAccountResourceId "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>" `
        -AzureBlobAccountKey "<storage key>" `
        -AzureBlobContainerName "migration" `
        -SourceSqlConnectionAuthentication "SqlAuthentication" `
        -SourceSqlConnectionDataSource "10.1.0.4" `
        -SourceSqlConnectionUserName "sqladmin" `
        -SourceSqlConnectionPassword $sourcePassword `
        -SourceDatabaseName "AdventureWorks2019" `
        -Offline `
        -OfflineConfigurationLastBackupName "<backup name>.bak"
    ```

    The following example creates and starts a migration of complete source database with target database name AdventureWorks:

    ```powershell
        New-AzDataMigrationToSqlManagedInstance `
        -ResourceGroupName oneclickpoc `
        -ManagedInstanceName sqlmicsapocmigration `
        -TargetDbName "AdventureWorks" `
        -Kind "SqlMI" `
        -Scope "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Sql/managedInstances/sqlmicsapocmigration" `
        -MigrationService "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.DataMigration/SqlMigrationServices/PoCMigrationService" `
        -AzureBlobStorageAccountResourceId "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Storage/storageAccounts/storagepocmigration" `
        -AzureBlobAccountKey "XXXXXX" `
        -AzureBlobContainerName "migration" `
        -SourceSqlConnectionAuthentication "SqlAuthentication" `
        -SourceSqlConnectionDataSource "10.1.0.4" `
        -SourceSqlConnectionUserName "sqladmin" `
        -SourceSqlConnectionPassword $sourcePassword `
        -SourceDatabaseName "AdventureWorks2019" `
        -Offline `
        -OfflineConfigurationLastBackupName "AdventureWorks2019.bak"
    ```

> [!TIP]
>
> You should take all necessary backups.

Learn more about using [Powershell to migrate](https://github.com/Azure-Samples/data-migration-sql/blob/main/PowerShell/sql-server-to-sql-mi-blob.md#start-online-database-migration)

### Monitoring migration

Use the **Get-AzDataMigrationToSqlManagedInstance** command to monitor migration.

1. Get complete migration details

    ```powershell
    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName <resource group name> `
    -SqlDbInstanceName <azure sql mi instance name> `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration
    ```

    The following example brings complete details

    ```powershell

    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName oneclickpoc `
    -SqlDbInstanceName sqlservercsapocmigration `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration
    
   ```

2. ProvisioningState should be **Creating, Failed, or Succeeded**

     ```powershell
    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName <resource group name> `
    -SqlDbInstanceName <azure sql mi instance name> `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration.ProvisioningState | Format-List
    ```

    The following example brings complete details

    ```powershell

    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName oneclickpoc `
    -SqlDbInstanceName sqlservercsapocmigration `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration.ProvisioningState | Format-List
    
   ```

3. MigrationStatus should be **InProgress, Canceling, Failed, or Succeeded**

    ```powershell
    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName <resource group name> `
    -SqlDbInstanceName <azure sql mi instance name> `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration.MigrationStatus | Format-List
    ```

    The following example brings complete details

    ```powershell

    $monitoringMigration = Get-AzDataMigrationToSqlManagedInstance  `
    -ResourceGroupName oneclickpoc `
    -SqlDbInstanceName sqlservercsapocmigration `
    -TargetDbName AdventureWorks `
    -Expand MigrationStatusDetails

    $monitoringMigration.MigrationStatus | Format-List
    ```

You can also use the Azure Portal to monitor migration.

![migration succeeded](/media/sqldb-migration-succeeded.png)

## Migrating at scale

This script performs an [end to end migration of multiple databases in multiple servers](https://github.com/Azure-Samples/data-migration-sql/tree/main/PowerShell/scripts/multiple%20databases)

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
