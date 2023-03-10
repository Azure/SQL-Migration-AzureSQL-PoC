[SQL Server migration one-click PoC to Azure SQL](../../README.md) > Online migration for Azure SQL Managed Instance

# Online migration for Azure SQL Managed Instance

Perform online migrations of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Database using the Azure SQL Migration extension.

## Migration using Azure storage

### Prerequisites

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 *(Already installed)*
- Azure CLI *(Already installed)*
- Az datamigration extension
- Azure storage account *(Already provisioned)*
- Azure Data Studio *(Already installed)*
- Azure SQL Migration extension for Azure Data Studio

1. Install az datamigration extension if it isn't installed. Open either a command shell or PowerShell as administrator.

    ```dotnetcli
    az extension add --name datamigration
    ```

2. Run the following to log in from your client using your default web browser

    ```dotnetcli
    az login
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```dotnetcli
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

```dotnetcli
az datamigration sql-managed-instance create `
--source-location '{\"AzureBlob\":{\"storageAccountResourceId\":\"/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Storage/storageAccounts/<StorageAccountName>\",\"accountKey\":\"<StorageKey>\",\"blobContainerName\":\"AdventureWorksContainer\"}}' `
--migration-service "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.DataMigration/SqlMigrationServices/MySqlMigrationService" `
--scope "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Sql/managedInstances/<ManagedInstanceName>" `
--source-database-name "AdventureWorks2019" `
--source-sql-connection authentication="SqlAuthentication" data-source="10.1.0.4" password="My$upp3r$ecret" user-name="sqladmin" `
--target-db-name "AdventureWorks2019" `
--resource-group <ResourceGroupName> `
--managed-instance-name <ManagedInstanceName>
```

> [!TIP]
> You should take all necessary backups.

Learn more about using [CLI to migrate](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-to-sql-mi-blob.md#start-online-database-migration)

### Monitoring migration

Use the **az datamigration sql-db show** command to monitor migration.

1. Basic migration details

    ```dotnetcli
    az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019"
    ```

2. Gets complete migration detail

    ```dotnetcli
    az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails
    ```

3. *ProvisioningState* should be "**Creating**", "**Failed**" or "**Succeeded**"

    ```dotnetcli
    az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.provisioningState"
    ```

4. *MigrationStatus* should be "**InProgress**", "**Canceling**", "**Failed**" or "**Succeeded**"

    ```dotnetcli
    az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.migrationStatus"

### Cutover for online migration

Use the **az datamigration sql-managed-instance cutover** command to perform cutover.

 1. Obtain the MigrationOperationId

```dotnetcli
$migOpId = az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.migrationOperationId"
```

 2. Perform Cutover

```dotnetcli
az datamigration sql-managed-instance cutover --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --migration-operation-id $migOpId
```

## Migrating at scale

This script performs an [end to end migration of multiple databases in multiple servers](https://github.com/Azure-Samples/data-migration-sql/tree/main/CLI/scripts/multiple%20databases)

## Page Navigator

[Deploy the solution for Azure SQL Managed Instance](../deploy/README.md)

[Assessment and SKU recommendation for Azure SQL Managed Instance](../assessment/README.md)

[Offline migration for Azure SQL Managed Instance](../migration/offline.md)

[SQL Server migration one-click PoC to Azure SQL](../../README.md)

[Index: Table of Contents](../../index.md)
