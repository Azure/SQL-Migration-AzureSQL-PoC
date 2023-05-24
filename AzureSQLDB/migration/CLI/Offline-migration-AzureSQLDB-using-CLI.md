[SQL Server migration one-click PoC to Azure SQL](../../README.md) > Offline migration for Azure SQL Database using CLI

# Offline migration for Azure SQL Database using CLI

Perform offline migrations of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Database using the Azure SQL Migration extension.

## Prerequisites

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 *(Already installed)*
- Azure CLI *(Already installed)*
- Integration Runtime *(Already installed)*
- Dotnet runtime *(Already installed)*
- Dotnet SDK *(Already installed)*
- Az datamigration extension

Open a [Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=us). It is already installed in the VM and by default it uses PowerShell.

1. Install az datamigration extension if it isn't installed.

    ```powershell
    az extension add --name datamigration
    ```

2. Run the following to log in from your client using your default web browser if you are not logged in.

    ```powershell
    az login
    ```

    If you have more than one subscription, you can select a particular subscription.

    ```powershell
    az account set --subscription <subscription-id>
    ```

    The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

    In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

### Register Database Migration Service with self-hosted Integration Runtime

1. Use the **az datamigration sql-service list-auth-key** command to obtain AuthKeys.

    ```powershell
    $AuthKey = az datamigration sql-service list-auth-key `
    --resource-group "<resource group name>" `
    --sql-migration-service-name "PoCMigrationService" ` 
    --query "authKey1"
    ```

    - The following example obtains the authKey:

    ```powershell
    $AuthKey = az datamigration sql-service list-auth-key `
    --resource-group "oneclickpoc" `
    --sql-migration-service-name "PoCMigrationService" `
    --query "authKey1"
    ```

2. Change the PowerShell execution policy.

    ```powershell
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
    ```

3. Use the **az datamigration register-integration-runtime** command to register the service on Integration Runtime.

    ```powershell
    az datamigration register-integration-runtime --auth-key <authKey>
    ```

    The following example registers the service on Integration Runtime:

    ```powershell
    az datamigration register-integration-runtime --auth-key $AuthKey
    ```

    > [!WARNING]
    > If you receive an error message saying: "RegisterIntegrationRuntime.ps1 cannot be loaded because running scripts is disabled on this system", please, run the following command and re-run the az command above.
    >
    > `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

### Perform a schema migration

Performing a schema migration can be accomplished using  [***SqlPackage***](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage?view=sql-server-ver16).

**SqlPackage.exe** is a command-line utility that automates the following database development tasks by exposing some of the public Data-Tier Application Framework (DacFx).

- **Extract metadata**

    Use the **SqlPackage /Action:Extract** command to extract metadata from your source

    ```powershell
    SqlPackage /Action:Extract `
    /TargetFile:"C:\temp\projects\adventureworks2019.dacpac" `
    /p:ExtractAllTableData=false `
    /p:ExtractReferencedServerScopedElements=false `
    /p:VerifyExtraction=true `
    /SourceServerName:"10.0.0.4" `
    /SourceDatabaseName:"AdventureWorks2019" `
    /SourceUser:"sqladmin" `
    /SourcePassword:"My`$upp3r`$ecret" `
    /SourceTrustServerCertificate:true
    ```

    > [!WARNING]
    > If you receive an error message, run the following command and re-run the command above.
    >
    > `dotnet tool install -g microsoft.sqlpackage`

- **Publish metadata**

    Use the **SqlPackage /Action:Publish** command to publish metadata to your Azure SQL database

    ```powershell
    SqlPackage /Action:Publish `
    /SourceFile:"C:\temp\projects\adventureworks2019.dacpac" `
    /p:CreateNewDatabase=false `
    /p:AllowIncompatiblePlatform=true `
    /p:ExcludeObjectTypes="Users;RoleMembership" `
    /Diagnostics:false `
    /TargetServerName:"<azure sq db instance>.database.windows.net" `
    /TargetDatabaseName:"AdventureWorks" `
    /TargetUser:"sqladmin" `
    /TargetPassword:"My`$upp3r`$ecret" `
    /TargetTrustServerCertificate:true
    ```

    > [!NOTE]
    > This command may take 3-5 minutes to complete.

You can also migrate the database schema from source to target using the [SQL Database Projects extension](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/sql-database-project-extension?view=sql-server-ver16) for Azure Data Studio.

### Start Database Migration

1. Use the **az datamigration sql-db create** command to create and start a database migration

    ```powershell
    
    az datamigration sql-db create `
    --migration-service "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.DataMigration/sqlMigrationServices/PoCMigrationService" `
    --scope "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Sql/servers/<azure sql db instance>" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.0.0.4" encrypt-connection=true password="My`$upp3r`$ecret" trust-server-certificate=false user-name="sqladmin" `
    --target-sql-connection authentication="SqlAuthentication" data-source="<azure sq db instance>.database.windows.net" encrypt-connection=true password="My`$upp3r`$ecret" trust-server-certificate=false user-name="sqladmin" `
    --resource-group "<resource group name>" `
    --sqldb-instance-name "<azure sql db instance>" `
    --target-db-name "AdventureWorks"
    ```

    The following example creates and starts a migration of complete source database with target database name AdventureWorks:

    ```powershell
    az datamigration sql-db create `
    --migration-service "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.DataMigration/sqlMigrationServices/PoCMigrationService" `
    --scope "/subscriptions/00000000-1111-2222-3333-444444444444/resourceGroups/oneclickpoc/providers/Microsoft.Sql/servers/sqlservercsapocmigration" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="10.0.0.4" encrypt-connection=true password="My`$upp3r`$ecret" trust-server-certificate=true user-name="sqladmin" `
    --target-sql-connection authentication="SqlAuthentication" data-source="sqlservercsapocmigration.database.windows.net" encrypt-connection=true password="My`$upp3r`$ecret" trust-server-certificate=true user-name="sqladmin" `
    --resource-group "oneclickpoc" `
    --sqldb-instance-name "sqlservercsapocmigration" `
    --target-db-name "AdventureWorks2019"
    ```

    > [!NOTE]
    > Migration may take a while to complete.

    Learn more about using [CLI to migrate](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-to-sql-db.md)

### Monitoring migration

Use the **az datamigration sql-db show** command to monitor migration.

1. Basic migration details

    ```powershell
    az datamigration sql-db show `
    --resource-group "<resource group name>" `
    --sqldb-instance-name "<azure sql db instance>" `
    --target-db-name "AdventureWorks"
    ```

    The following example brings basic details

    ```powershell
    az datamigration sql-db show `
    --resource-group "oneclickpoc" `
    --sqldb-instance-name "sqlservercsapocmigration" `
    --target-db-name "AdventureWorks"
   ```

2. Gets complete migration detail

    ```powershell
    az datamigration sql-db show `
    --resource-group "<resource group name>" `
    --sqldb-instance-name "<azure sql db instance>" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails
    ```

    The following example Gets complete details

    ```powershell
    az datamigration sql-db show `
    --resource-group "oneclickpoc" `
    --sqldb-instance-name "sqlservercsapocmigration" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails
    ```

3. ProvisioningState should be **Creating, Failed, or Succeeded**

    ```powershell
    az datamigration sql-db show `
    --resource-group "<resource group name>" `
    --sqldb-instance-name "<azure sql db instance>" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails `
    --query "properties.provisioningState"
    ```

    The following example gets the provisioning states

    ```powershell
    az datamigration sql-db show `
    --resource-group "oneclickpoc" `
    --sqldb-instance-name "sqlservercsapocmigration" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails `
    --query "properties.provisioningState"
    ```

4. MigrationStatus should be **InProgress, Canceling, Failed, or Succeeded**

    ```powershell
    az datamigration sql-db show `
    --resource-group "<resource group name>" `
    --sqldb-instance-name "<azure sql db instance>" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails `
    --query "properties.migrationStatus"
    ```

    The following example gets the migration status

    ```powershell
    az datamigration sql-db show `
    --resource-group "oneclickpoc" `
    --sqldb-instance-name "sqlservercsapocmigration" `
    --target-db-name "AdventureWorks" `
    --expand MigrationStatusDetails `
    --query "properties.migrationStatus"
    ```

You can also use the Azure Portal to monitor migration.

![migration succeeded](/media/sqldb-migration-succeeded.png)

## Migrating at scale

This script performs an [end to end migration of multiple databases in multiple servers](https://github.com/Azure-Samples/data-migration-sql/tree/main/CLI/scripts/multiple%20databases)

## Page Navigator

[Deploy the solution for Azure SQL Database](../deploy/README.md)

[Assessment and SKU recommendation for Azure SQL Database](../assessment/README.md)

[SQL Server migration one-click PoC to Azure SQL](../../README.md)

[Index: Table of Contents](../../index.md)
