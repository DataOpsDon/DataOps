
// Resources
@description('The workload for the resources')
param workload string

@description('The environment for the resources')
param environment string

@maxLength(3)
@description('The region for the resources')
param region string

@description('The naming convention for the resources')
param namingConvention string = '${workload}-${region}-${environment}'
//
@description('The naming convention for the resources without dashes')
param namingConventionNoDashes string = '${workload}${region}${environment}'

@description('The name for the Action Group')
param actionGroup string = 'acg${workload}'

@description('The name for the Key Vault')
param keyVault string  = 'kv-${namingConvention}'

@description('The name for the Storage Account')
param storageAccountName string = 'sta${namingConventionNoDashes}'

@description('The name for the Bastion')
param bastion string = 'bh-${namingConvention}'

@description('The name for the Log Analytics Workspace')
param logAnalytics string = 'log-alw-${namingConvention}'

@description('The name for the Application Insights')
param appInsights string = 'app-ins-${namingConvention}'

@description('The name for the App Service Plan')
param appServicePlan string = 'host-pln-${namingConvention}'

@description('The name for the Function App')
param functionApp string = 'azu-fap-${namingConvention}'

@description('The name for the Databricks Workspace')
param databricks string = 'dbw-${namingConvention}'

@description('The name for the Databricks Workspace Connector')
param databricksConnector string = 'dbwac-${namingConvention}'

@description('The name for the SQL Server')
param sqlServer string = 'sql-svr-${namingConvention}'

@description('The name for the SQL Db')
param sqlDb string = 'sql-db-${namingConvention}'

@description('The name for the Data Factory')
param dataFactory string = 'adf-${namingConvention}'

@description('The name for the Event Grid Topic')
param eventGridTopic string = 'evg-${namingConvention}'

@description('The name of the resource Group')
param resourceGroupName string = 'rg-${namingConvention}'

@description('The name for NSG')
param nsgName string = 'nsg-${namingConvention}'

@description('The name for Route Table')
param routeTableName string = 'rt-${namingConvention}'

@description('The name for the Subnet')
param subnetName string = 'snet-${namingConvention}'

@description('The name for the VNet')
param vnetName string = 'vnet-${namingConvention}'

@description('The name for the Virtual Machine Scale-Set')
param vmssName string = 'vmss${namingConvention}'

@description('The name for the Virtual Machine')
param vmName string = 'vm${namingConventionNoDashes}'

// Outputs
@maxLength(29)
@description('The output name for the Key Vault')
output keyVaultName string = keyVault 

@maxLength(24)
@description('The output name for the Storage Account')
output storageAccountName string = storageAccountName

@description('The output name for the Log Analytics Workspace')
output logAnalyticsName string = logAnalytics

@description('The output name for the Application Insights')
output appInsightsName string = appInsights

@description('The output name for the App Service Plan')
output appServicePlanName string = appServicePlan

@description('The output name for the Function App')
output functionAppName string = functionApp

@description('The output name for the Databricks Workspace')
output databricksName string = databricks

@description('The output name for the SQL Server')
output sqlServerName string = sqlServer

@description('The output name for the Data Factory')
output dataFactoryName string = dataFactory

@description('The output name for the Event Grid Topic')
output eventGridTopicName string = eventGridTopic

@description('The output name of the resource Group')
output resourceGroupName string = resourceGroupName

@description('The output name for the Action Group')
output actionGroupName string = actionGroup

@description('The output name for the SQL Db')
output sqlDbName string = sqlDb

@description('The output name for the NSG')
output nsgName string = nsgName

@description('The output name for the Route Table')
output routeTableName string = routeTableName

@description('The output name for the Subnet')
output subnetName string = subnetName

@description('The output name for the VNet')
output vnetName string = vnetName

@description('The output name for the Virtual Machine Scale-Set')
output vmssName string = vmssName

@description('The output name for the Virtual Machine')
output vmName string = vmName

@description('The output name for the Databricks Workspace Connector')
output databricksConnectorName string = databricksConnector

@description('The output name for the Bastion')
output bastionName string = bastion
