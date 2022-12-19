[SQL Server migration one-click PoC to Azure SQL](../../README.md) > Assessment and SKU recommendation for Azure SQL Managed Instance

# Assessment and SKU recommendation for Azure SQL Managed Instance

Assess your SQL Server databases for Azure SQL Managed Instance readiness or identify any migration blockers before migrating them to Azure SQL Managed Instance.

The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure SQL.

In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

## Prerequisites

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 (Already installed in the Jumpbox VM)
- Azure CLI (Already installed in the Jumpbox VM)
- Az datamigration extension

## Getting Started

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.

1. Install az datamigration extension. Open either a command shell or PowerShell as administrator.

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

## Run the assessment

1. We can run a SQL server assessment using the ***az datamigration get-assessment*** command.

    ```dotnetcli
    az datamigration get-assessment --connection-string "Data Source=10.1.0.4,1433;Initial Catalog=master;User Id=sqladmin;Password=My$upp3r$ecret" --output-folder "C:\temp\output" --overwrite
    ```

2. Assessment at scale using config file

    You can also create a config file to use as a parameter to run assessments on SQL servers. The config file has the following structure:

    ```json
    {
        "action": "Assess",
        "outputFolder": "C:\\temp\\output",
        "overwrite":  "True",
        "sqlConnectionStrings": [
            "Data Source=Server1.database.net;Initial Catalog=master;Integrated Security=True;",
            "Data Source=Server2.database.net;Initial Catalog=master;Integrated Security=True;"
        ]
    }
    ```

    The config file can be passed to the cmdlet in the following way

    ```dotnetcli
    az datamigration get-assessment --config-file-path "C:\Users\user\document\config.json"
    ```

    > [!TIP]
    > To view the report, go to **C:\temp\output** folder and check the json file.

    Learn more about using [CLI to assess sql server](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-assessment.md)

## SKU Recommendation

### Performance data collection

This step is optional. An Azure SQL Managed Instance has been already provisioned.

1. Run a SQL server performance data collection using the ***az datamigration performance-data-collection*** command.

    ```dotnetcli
    az datamigration performance-data-collection --connection-string "Data Source=10.1.0.4,1433;Initial Catalog=master;User Id=sqladmin;Password=My$upp3r$ecret" --output-folder "C:\temp\output" --perf-query-interval 10 --number-of-iteration 5 --static-query-interval 120
    ```

    > [!TIP]
    > Collect as much data as you want, then stop the process.
    > To view the report, go to **C:\temp\output** folder and check the report file.

2. Running **performance data collection at scale** using config file

    You can also create a config file to use as a parameter to run performance data collection on SQL servers.
    The config file has the following structure:

    ```json
    {
        "action": "PerfDataCollection",
        "outputFolder": "C:\\temp\\output",
        "perfQueryIntervalInSec": 20,
        "staticQueryIntervalInSec": 120,
        "numberOfIterations": 7,
        "sqlConnectionStrings": [
            "Data Source=Server1.database.net;Initial Catalog=master;Integrated Security=True;",
            "Data Source=Server2.database.net;Initial Catalog=master;Integrated Security=True;"
        ]
    }
    ```

    The config file can be passed to the cmdlet in the following way.

    ```dotnetcli
    az datamigration performance-data-collection --config-file-path "C:\Users\user\document\config.json"
    ```

    > [!TIP]
    > You can look into the output folder to find a CSV file that also gives the details of the performance data collected.

    Learn more about using [CLI to perform data collection](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md#performance-data-collection-using-connection-string)

### Get SKU Recommendation

This step is optional. An Azure SQL Managed Instance has been already provisioned.

1. Get SKU recommendation using the **az datamigration get-sku-recommendation** command.

    ```dotnetcli
    az datamigration get-sku-recommendation --output-folder "C:\temp\output" --display-result --overwrite --target-platform "AzureSqlManagedInstance"`
    ```

2. Get SKU recommendations at scale using a config file.

    We can also create a config file to use as a parameter to get SKU recommendations on SQL servers. The config file has the following structure:

    ```json
    {
        "action": "GetSKURecommendation",
        "outputFolder": "C:\\temp\\Output",
        "overwrite":  "True",
        "displayResult": "True",
        "targetPlatform": "any",
        "scalingFactor": 1000
    }
    ```

    > [!TIP]
    > You can look into the output folder to find an HTML file that also gives the details of the SKU being recommended.

    Learn more about using [CLI to get SKU recommendation](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md#performance-data-collection-using-connection-string)

## Page Navigator

[Deploy the solution for Azure SQL Managed Instance](../deploy/README.md)

[Offline migration for Azure SQL Managed Instance](../migration/offline.md)

[Online migration for Azure SQL Managed Instance](../migration/online.md)

[SQL Server migration one-click PoC to Azure SQL](../../README.md)

[Index: Table of Contents](../../index.md)
