using './hub.bicep'

param resourceGroupName = 'rg-dbw-hub-uks-${environment}-01'
param location = 'uksouth'
param addressPrefix = '10.5.0.0/24'
param environment = 'dev'
param databricksManagedResourceGroupName = 'rg-dbw-databricks-uks-${environment}-01'
param vmPassword = 'gjikwdjitgwkrj!!KOF5'
