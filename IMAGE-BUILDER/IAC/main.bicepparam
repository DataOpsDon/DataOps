using './main.bicep'

param identityResourceGroupName = 'rg-img-identity-uks-01'
param managedIdentityName = 'ui-img-identity-uks-01'
param location = 'uksouth'
param vnetResourceGroupName = 'rg-img-network-uks-01'
param vnetName = 'vnet-img-network-uks-01'
param addressPrefixes = [
  '10.0.0.0/24'
 ]
param  nsgName = 'nsg-img-network-uks-01'
param subscriptionId = '20c18e76-0e32-4099-b9cc-afcec9b9e086'
param imageBuilderName  = 'ib-img-imge-uks-01'
param imageResourceGroupName = 'rg-img-imge-uks-01' 
param stagingResourceGroupName = 'rg-img-staging-uks-01' 
param imageName = 'img-imge-uks-01'
