using './spoke.bicep'

param resourceGroupName = 'rg-dbw-spoke-uks-${environment}-01'
param databricksManagedResourceGroupName = 'rg-dbw-spoke-uks-${environment}-02'
param location = 'uksouth'
param addressPrefix = '10.6.0.0/24'
param environment = 'dev'

