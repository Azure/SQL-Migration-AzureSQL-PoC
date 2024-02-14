# Assessment and SKU recommendation for Azure SQL Database using CLI

Assess your SQL Server databases for Azure SQL Database readiness or to identify any migration blockers before migrating them to Azure SQL Database.

The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure SQL.

In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

## Prerequisites

- SQL Server with Windows authentication or SQL authentication access
- .Net Core 3.1 (Already installed)
- Azure CLI (Already installed)
- Az datamigration extension

## Getting Started

> [!CAUTION]
>
> - **Connect to the Jump Box VM**
> - VM name: **jb-migration**
> - Use the credentials provided on the deploy page.
>

Open a [Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=us). It is already installed in the VM and by default it uses PowerShell.

1. Install az datamigration extension. Open either a command shell or PowerShell as administrator.

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

## Run the assessment

1. Run a SQL Server assessment using the ***az datamigration get-assessment*** command.

    ```azurecli
    az datamigration get-assessment `
    --connection-string "Data Source=10.0.0.4,1433;Initial Catalog=master;User Id=sqladmin;Password=My`$upp3r`$ecret" `
    --output-folder "C:\temp\output" `
    --overwrite
    ```

2. **Assessment at scale** using config file

    You can also create a config file to use as a parameter to run assessment on SQL servers. The config file has the following structure:

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

    ```azurecli
    az datamigration get-assessment --config-file-path "C:\Users\user\document\config.json"
    ```

    > [!NOTE]
    > To view the report, go to **C:\temp\output** folder and check the json file.

    Learn more about using [CLI to assess SQL Server](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-assessment.md)

## SKU Recommendation

### Performance data collection

This step is optional. An Azure SQL DB has been already provisioned.

1. Run a SQL Server performance data collection using the ***az datamigration performance-data-collection*** command.

    ```azurecli
    az datamigration performance-data-collection `
    --connection-string "Data Source=10.0.0.4,1433;Initial Catalog=master;User Id=sqladmin;Password=My`$upp3r`$ecret" `
    --output-folder "C:\temp\output" `
    --perf-query-interval 10 `
    --number-of-iteration 5 `
    --static-query-interval 120
    ```

    > [!NOTE]
    > Collect as much data as you want, then stop the process.
    > You can look into the output folder (**C:\temp\output**) to find a CSV file that also gives the details of the performance data collected.

2. Running **performance data collection at scale** using a config file

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

    ```azurecli
    az datamigration performance-data-collection --config-file-path "C:\Users\user\document\config.json"
    ```

    > [!NOTE]
    > Collect as much data as you want, then stop the process.
    > You can look into the output folder (**C:\temp\output**) to find a CSV file that also gives the details of the performance data collected.

    Learn more about using [CLI to perform data collection](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md)

### Get SKU Recommendation

This step is optional. An Azure SQL DB has been already provisioned.

1. Get SKU recommendation using the **az datamigration get-sku-recommendation** command.

    ```azurecli
    az datamigration get-sku-recommendation `
    --output-folder "C:\temp\output" `
    --display-result `
    --overwrite `
    --target-platform "AzureSqlDatabase"
    ```

    All results will be displayed after the command finishes.

    ![sku-recommendation](/media/sqldb-sku-recommendation-cli.png)

2. Get SKU recommendations at scale using a config file.

    You can also create a config file to use as a parameter to get SKU recommendations on SQL servers. The config file has the following structure:

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

    Learn more about using [CLI to get SKU recommendation](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md#get-sku-recommendation-though-console-parameters)

3. HTML recommendations result

    > You can look into the output folder (C:\temp\output) to find an HTML file that also gives the details of the SKU being recommended.

    ![sku-recommendation-html](../../../media/sqldb-sku-recommendation-html.png)

## Page Navigator

- [SQL Server migration one-click PoC to Azure SQL](../../../README.md)
- [One-click PoC to Azure SQL DB](../../../AzureSQLDB/deploy/README.md)
- [One-click PoC to Azure SQL MI](../../../AzureSQLMI/deploy/README.md)
