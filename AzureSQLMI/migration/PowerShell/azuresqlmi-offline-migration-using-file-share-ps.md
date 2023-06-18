# Offline migration for Azure SQL Managed Instance using File Share using PowerShell

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

    ```sql
    USE master
    BACKUP DATABASE AdventureWorks2019 TO Disk = 'C:\temp\backup\AdventureWorks2019.bak'
    WITH CHECKSUM
    ```

### Register Database Migration Service with self-hosted Integration Runtime

1. Use the **Get-AzDataMigrationSqlServiceAuthKey** command to obtain AuthKeys.

    ```powershell
    $AuthKeys = Get-AzDataMigrationSqlServiceAuthKey `
    -ResourceGroupName "<resource group name>" `
    -SqlMigrationServiceName "PoCMigrationService"
    ```

    - The following example obtains the authKey:

    ```powershell
    $AuthKeys = Get-AzDataMigrationSqlServiceAuthKey `
    -ResourceGroupName "oneclickpoc" `
    -SqlMigrationServiceName "PoCMigrationService"
    ```

2. Change the PowerShell execution policy.

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

3. Use the **az datamigration register-integration-runtime** command to register the service on Integration Runtime.

    ```powershell
    Register-AzDataMigrationIntegrationRuntime `
    -AuthKey <authKey> `
    ```

    The following example registers the service on Integration Runtime:

    ```powershell
    Register-AzDataMigrationIntegrationRuntime `
    -AuthKey $AuthKeys.AuthKey1 `
    ```

    > [!WARNING]
    > If you receive an error message saying: "RegisterIntegrationRuntime.ps1 cannot be loaded because running scripts is disabled on this system", please, run the following command and re-run the PowerShell command above.
    >
    > `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

### Start database migration

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

1. Convert the passwords to secure string

    ```powershell
    $sourcePassword = ConvertTo-SecureString "My`$upp3r`$ecret" -AsPlainText -Force
    $sourceFileSharePassword = ConvertTo-SecureString "My`$upp3r`$ecret" -AsPlainText -Force
    
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
        -StorageAccountResourceId "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>" `
        -StorageAccountKey "<storage key>" `
        -FileSharePath "\\sqlvm-001\SQLBackup" `
        -FileShareUsername "sqlvm-001\sqladmin" `
        -FileSharePassword $sourceFileSharePassword `
        -SourceSqlConnectionAuthentication "SqlAuthentication" `
        -SourceSqlConnectionDataSource "10.1.0.4" `
        -SourceSqlConnectionUserName "sqladmin" `
        -SourceSqlConnectionPassword $sourcePassword `
        -SourceDatabaseName "AdventureWorks2019" `
        -Offline 
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
        -StorageAccountResourceId "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Storage/storageAccounts/storagepocmigration" `
        -StorageAccountKey "XXXXXXXX" `
        -FileSharePath "\\10.1.0.4\SQLBackup" `
        -FileShareUsername "10.1.0.4\sqladmin" `
        -FileSharePassword $sourceFileSharePassword `
        -SourceSqlConnectionAuthentication "SqlAuthentication" `
        -SourceSqlConnectionDataSource "10.1.0.4" `
        -SourceSqlConnectionUserName "sqladmin" `
        -SourceSqlConnectionPassword $sourcePassword `
        -SourceDatabaseName "AdventureWorks2019" `
        -Offline 
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
    -SqlDbInstanceName <azure sql db instance> `
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
    -SqlDbInstanceName <azure sql db instance> `
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
    -SqlDbInstanceName <azure sql db instance> `
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
