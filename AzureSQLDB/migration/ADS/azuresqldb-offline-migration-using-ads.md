# Offline migration for Azure SQL Database using Azure Data Studio

Perform offline migrations of your SQL Server databases running on-premises, SQL Server on Azure Virtual Machines, or any virtual machine running in the cloud (private, public) to Azure SQL Database using Azure Data Studio and Azure SQL Migration extension.

[Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/what-is-azure-data-studio) is a unified tooling experience for data professionals.

The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure SQL.

## Getting Started

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

## Installing Azure SQL Migration Extension

> [!NOTE]
> If you've already installed it, feel free to skip this step.

- Launch Azure Data Studio.
- Navigate to the "Extensions" tab located in the right-side menu.
- In the search bar, type "Azure SQL Migration" and press Enter.
- Locate the "Azure SQL Migration" extension from the search results.
- Click on the "Install" button next to the extension to begin the installation process.

![ads-assessment-install-extension](../../../media/ADS/ads-assessment-install-extension.png)

## Connecting to SQL Server

After successfully installing the extension, follow these steps to connect to the SQL Server:

- Navigate to the "Connections" tab in the top menu.
- Click on "New Connection" to open the connection dialog.
- In the "Server" field, enter the following: `10.0.0.4`
- Choose "Windows Authentication" as the authentication type.
- Set "Trust server certificate" to "True".
- Click "Connect" to establish the connection to the SQL Server.

![ads-assessment-connect-sql](/media/ADS/ads-sqldb-assessment-connect-sql.png)

After establishing the connection, the Manage page will appear.

- Go to the sidebar menu and select "General" to find the "Azure SQL Migration" extension.
- Click on the "Azure SQL Migration" extension to open it and begin using its features for migration tasks.

After accessing the home page of Azure SQL Migration, follow these steps:

- Look for the "+ New migration" button and click on it.
- Choose all databases that you want to include in the assessment.
- Click "Next" to proceed to the next step in the migration process.
  
## Starting a migration

After accessing the home page of Azure SQL Migration, follow these steps:

- Look for the "+ New migration" button and click on it.
- Choose all databases that you want to include in the assessment.
- Click "Next" to proceed to the next step in the migration process.

![ads-assessment-migration-extension-home](/media/ADS/ads-sqldb-assessment-migration-extension-home.png)

- Click on the checkbox to select "AdventureWorks2019"database available for assessment.
- Once the database is selected, proceed to the next step in the migration process.

![ads-migration-select-databases](/media/ADS/ads-sqldb-migration-select-databases.png)

### Performance data collection and SKU recommendation

- After a few minutes, a summary will appear, allowing you to review the assessment for Azure SQL targets.
- You can review the perfomance data collection and sku recommendation [here](/AzureSQLDB/assessment/ADS/azuresqldb-assessment-sku-using-ads.md). This step will be skipped.

### Selection target platform

- Proceed by clicking "Next".
- Select "Azure SQL Database" as the target type.

![ads-assessment-summary](/media/ADS/ads-sqldb-migration-target-platform.png)

- Click "Next".

### Azure SQL target

1. Link your account to Azure Data Studio by clicking "Link account".
2. Proceed with the authentication process.
3. After authentication, select the subscription, location, and Azure SQL Database server.
4. Enter the target username and password, using the same ones provided on the deployment page.
5. Click "Connect".
6. Select the target database "AdventureWorks".
7. Click "Next".

![ads-sqldb-migration-sql-target](/media/ADS/ads-sqldb-migration-sql-target.png)

### Register Database Migration Service with self-hosted Integration Runtime

At this moment, Azure Database Migration Service is not registered.
It's time to register it.

![ads-sqldb-migration-sql-target](/media/ADS/ads-sqldb-migration-register-dms.png)

Certainly, here are the steps broken down:

1. Go back to the Azure Portal.
2. Find the resource group where you deployed this solution.
3. Locate the resource named "PocMigrationService" within the resource group.
4. Access the "PocMigrationService" resource.
5. Click on "View integration runtime".

![ads-sqldb-migration-register-dms-portal](/media/ADS/ads-sqldb-migration-register-dms-portal.png)

You will notice that there is no Integration runtime set up. 
Let's set up a new one. 
click "Configuration integration runtime"

You'll notice that there's currently no Integration Runtime set up.
Let's establish a new one.

- Click on "Configuration integration runtime".

![ads-sqldb-migration-register-dms-conf-ir](/media/ADS/ads-sqldb-migration-register-dms-conf-ir.png)

A new window will open with instructions on how to download and install the integration runtime.
However, there's no need to download and install it. 

We will simply register it.

- Copy authentication key #1.

Now, return to the "JB-Migration" VM.

#### Register Integration runtime

1. On the Windows search bar, type "Microsoft Integration Runtime" and press Enter.
2. Open the Microsoft Integration Runtime app.
3. Paste the key you copied from the Azure Portal into the "Register Integration Runtime (Self-hosted)" field.
4. Click "Register".

![ads-sqldb-migration-register-dms-key](/media/ADS/ads-sqldb-migration-register-dms-key.png)

After a few minutes, the registration process will be completed, and you'll see the Integration Runtime node has been successfully registered.

You can also observe that information about the Integration Runtime is now available in the Azure Portal.

![ads-sqldb-migration-register-dms-portal-success](/media/ADS/ads-sqldb-migration-register-dms-portal-success.png)

After successfully registering the integration runtime, return to Azure Data Studio, and then click the "Refresh" button.

![ads-sqldb-migration-register-dms-success](/media/ADS/ads-sqldb-migration-register-dms-success.png)

1. Click "Next".
2. Insert the password to connect to the SQL Server.
3. On the "Table selection" page, click "Edit" to migrate table schema and data.

### Schema and Data migration

![ads-sqldb-migration-datasource-conf](/media/ADS/ads-sqldb-migration-datasource-conf.png)

1. Switch to the "Missing on target" tab.
2. Select all tables.
3. Ensure that the "Migration schema to target" option is selected.
4. Click "Update"

![ads-sqldb-migration-datasource-conf](/media/ADS/ads-sqldb-migration-datasource-tables.png)

The last step before starting the migration is to run a validation.

1. Click "Run validation".
2. The validation process will start and finish successfully after a few minutes.
3. Click "Done" and then "Next" to proceed.

![ads-sqldb-migration-run-validation](/media/ADS/ads-sqldb-migration-run-validation.png)

Review the migration summary and click "Start migration"

![ads-sqldb-migration-summary](/media/ADS/ads-sqldb-migration-summary.png)

### Monitoring migration

Now, the migration will start, and you can monitor its progress on the home page of the Azure SQL Migration extension. Keep an eye on the status updates and any notifications for insights into the migration process.

![ads-sqldb-migration-monitoring-homepage](/media/ADS/ads-sqldb-migration-monitoring-homepage.png)

- Click "Database migrations in progress".
- After a few minutes, you'll see the migration status indicating "in progress".


![ads-sqldb-migration-monitoring-overview](/media/ADS/ads-sqldb-migration-monitoring-overview.png)

- Click on the source database "AdventureWorks2019" to get more details.
- After a few minutes, the migration will complete successfully.

![ads-sqldb-migration-monitoring-details](/media/ADS/ads-sqldb-migration-monitoring-details.png)

## Page Navigator

- [SQL Server migration one-click PoC to Azure SQL](../../../README.md)
- [One-click PoC to Azure SQL DB](../../../AzureSQLDB/deploy/README.md)
- [One-click PoC to Azure SQL MI](../../../AzureSQLMI/deploy/README.md)
