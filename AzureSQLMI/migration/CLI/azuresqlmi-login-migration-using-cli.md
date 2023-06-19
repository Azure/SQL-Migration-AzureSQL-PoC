# Login migration for Azure SQL Managed Instance using CLI

Perform a login migration of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Managed Instance using the Azure SQL Migration extension.

## Migration using Azure storage

### Prerequisites

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 *(Already installed)*
- Azure CLI *(Already installed)*
- Az datamigration extension
- Azure storage account *(Already provisioned)*
- Azure Data Studio *(Already installed)*
- Azure SQL Migration extension for Azure Data Studio

Currently, only Azure SQL Managed Instance and SQL Server on Azure Virtual Machines targets are supported.

Completing the database migrations of your on-premises databases to Azure SQL before starting the login migration is ***recommended***. It will ensure that the database-level users have already been migrated to the target; therefore the login migration process will perform the user-login mappings synchronization.

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

3. Verify SQL Logins to be migrated

    Open the Azure Data Studio, connect to the *Azure SQL VM* (**10.1.0.4**) using the "**sqladmin**" user and password and run the following T-SQL statement to see all SQL Logins.

    ```sql
    SELECT 
        sp.name AS server_login_name, 
        dp.name AS database_user_name, 
        sp.type_desc, 
        sp.is_disabled
    FROM sys.server_principals AS sp
    INNER JOIN WideWorldImportersDW.sys.database_principals AS dp ON SP.sid = DP.sid
    ```

### Start login migration

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

At this point you will need to get the Azure SQL MI name. [Get server connection information](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-content-reference-guide?view=azuresql#get-server-connection-information)

![sqlmi-connectionstring](../../../media/sqlmi-connectionstring.png)

1. Use the **az datamigration login-migration** command to create and start a database migration.

    ```azurecli
        az datamigration login-migration  `
        --src-sql-connection-str  "data source=10.1.0.4,1433;user id=sqladmin;password=My`$upp3r`$ecret;initial catalog=master;TrustServerCertificate=True" `
        --tgt-sql-connection-str  "data source=<managed instance name>.database.windows.net;user id=sqladmin;password=My`$upp3r`$ecret;initial catalog=master;TrustServerCertificate=True" `
        --list-of-login "sqlpoc" "sqlpocapp" "sqlpocreport" `
        --output-folder "C:\temp\output"
    ```

    > [!WARNING]
    >
    > Change the **managed instance name**

    > [!TIP]
    >
    > Windows accounts are out of scope but if you want to learn how to migrate them, check out this [prerequisites](<https://learn.microsoft.com/en-us/azure/dms/tutorial-login-migration-ads#prerequisites>

    ![sqlmi-login-migration](../../../media/sqlmi-login-migration-cli.png)

2. **Login migration at scale** using config file

    Learn more about [Migrate SQL Server logins](https://learn.microsoft.com/en-us/azure/dms/tutorial-login-migration-ads#configure-login-migration-settings)

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
