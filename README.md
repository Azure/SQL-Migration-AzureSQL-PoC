# SQL Server migration one-click PoC to Azure SQL

This one-click deployment allows you to deploy a Proof-of-Concept environment of Azure SQL VM migration to Azure SQL with encapsulated best practices and step-by-step execution steps that will enable you to test, adjust and fully deploy the automated solution at scale.
This approach can help with large-scale migrations for specific workload use cases.

## One-click PoC

Take advantage of this one-click SQL Migration PoC to accelerate your migration to Azure SQL.

|Deployment Options                         | One-Click PoC  |
|---------                                  | ---------      |
| SQL Server to Azure SQL Managed Instance  | [![One-click PoC to Azure SQL MI](./media/Azure-DevOps.svg)](./AzureSQLMI/deploy/README.md) [One-click PoC to Azure SQL MI](./AzureSQLMI/deploy/README.md)         |
| SQL Server to Azure SQL Database          | [![One-click PoC to Azure SQL DB](./media/Azure-DevOps.svg)](./AzureSQLDB/deploy/README.md) [One-click PoC to Azure SQL DB](./AzureSQLDB/deploy/README.md)         |

## Migration Scenarios

| Destination | Migration Scenario | Scripting language |
|---------    |---------           |:---------:           |
| Azure SQL DB | Assessment and SKU recommendation | [CLI](./AzureSQLDB/assessment/CLI/azuresqldb-assessment-sku-using-cli.md) / [PowerShell](./AzureSQLDB/assessment/PowerShell/azuresqldb-assessment-sku-using-ps.md) |
| Azure SQL DB | Offline migration for Azure SQL Database | [CLI](./AzureSQLDB/migration/CLI/azuresqldb-offline-migration-using-cli.md) / [PowerShell](/AzureSQLDB/migration/PowerShell/azuresqldb-offline-migration-using-ps.md)|
|Azure SQL MI | Assessment and SKU recommendation | [CLI](./AzureSQLMI/assessment/CLI/azuresqlmi-assessment-sku-using-cli.md) / [PowerShell](./AzureSQLMI/assessment/PowerShell/azuresqlmi-assessment-sku-using-ps.md) |
|Azure SQL MI | Offline migration for Azure SQL Managed Instance using Storage Account | [CLI](./AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-azure-storage-cli.md) / [PowerShell](/AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-azure-storage-ps.md)|
|Azure SQL MI | Offline migration for Azure SQL Managed Instance using File Share | [CLI](./AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-file-share-cli.md) / [PowerShell](/AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-file-share-ps.md) |
|Azure SQL MI | Online migration for Azure SQL Managed Instance using Storage Account | [CLI](./AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-azure-storage-cli.md) / [PowerShell](/AzureSQLMI/migration/PowerShell/azuresqlmi-online-migration-using-azure-storage-ps.md)|
|Azure SQL MI | Online migration for Azure SQL Managed Instance using File Share | [CLI](./AzureSQLMI/migration/CLI/azuresqlmi-offline-migration-using-file-share-cli.md) / [PowerShell](/AzureSQLMI/migration/PowerShell/azuresqlmi-offline-migration-using-file-share-ps.md)
|Azure SQL MI | Login migration | [CLI](./AzureSQLMI/migration/CLI/azuresqlmi-login-migration-using-cli.md) / [PowerShell](/AzureSQLMI/migration/PowerShell/azuresqlmi-login-migration-using-ps.md) |

## Youtube walkthrough

This short video will help you to get familiarized with the SQL Server migration one-click PoC to Azure SQL.

[![Youtube SQL Server migration one-click PoC to Azure SQL](https://img.youtube.com/vi/qHaGY1oP7WU/0.jpg)](https://www.youtube.com/watch?v=qHaGY1oP7WU)

## Prerequisites

- You need to have at least an owner role or contributor role for the Azure subscription. A separate resource group should be created and delegated roles necessary for this proof of concept.
- Check this documentation for [RBAC role-assignments](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-steps).
- Make sure that the Microsoft.DataMigration [resource provider is registered in your subscription.](https://learn.microsoft.com/en-us/azure/dms/quickstart-create-data-migration-service-portal#register-the-resource-provider)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
