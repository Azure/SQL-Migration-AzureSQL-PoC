[SQL Server migration one-click PoC to Azure SQL](../../README.md) > Login migration for Azure SQL Managed Instance using CLI

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

    Open the Azure Data Studio and run the following T-SQL statement to see all SQL Logins.

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
    > Change the **Managed Instance name**

    > [!TIP]
    >
    > Currently, only Azure SQL Managed Instance and SQL Server on Azure Virtual Machines targets are supported.
    >
    > Windows accounts are out of scope but if you want to learn how to migrate them, check out this [prerequisites](<https://learn.microsoft.com/en-us/azure/dms/tutorial-login-migration-ads#prerequisites>

2. **Login migration at scale** using config file

Learn more about [Migrate SQL Server logins](https://learn.microsoft.com/en-us/azure/dms/tutorial-login-migration-ads#configure-login-migration-settings)

## Page Navigator

[Deploy the solution for Azure SQL Managed Instance](../deploy/README.md)

[Assessment and SKU recommendation for Azure SQL Managed Instance](../assessment/README.md)

[Online migration for Azure SQL Managed Instance](../migration/online.md)

[SQL Server migration one-click PoC to Azure SQL](../../README.md)

[Index: Table of Contents](../../index.md)
