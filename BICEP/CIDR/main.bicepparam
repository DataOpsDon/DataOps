using './main.bicep'

param location = 'uksouth'
param vnetResourceGroupName = 'rg-bice-cidr-01'
param vnetName = 'vnet-bice-cidr-01'
param addressPrefixes = '10.0.0.0/24'
param nsgName = 'nsg-bice-cidr-01'
param routeTableName = 'rt-bice-cidr-01'

