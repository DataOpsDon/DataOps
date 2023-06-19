@description('The location of the Virtual Network')
@allowed([
  'uksouth'
  'ukswest' ])
param location string = 'uksouth'

@description('The address space of the Virtual Network')
param addressSpace string = '10.0.0.0/16'

@description('The name of the Virtual Network')
param vnetName string = 'vnet-cidr-dev-uks-01'

@description('The number of subnets to create')
param itemCount int = 5

//Calculate the subnets
var snets = [for i in range(0, 4): cidrSubnet('10.0.0.0/16', 27, i)]

//Create the subnet names
var snetname = [for i in range(0, itemCount): 'snet${(i + 1)}']

resource vnet_resource 'Microsoft.Network/virtualNetworks@2019-12-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    virtualNetworkPeerings: []
    enableVmProtection: false
  }
}

@batchSize(1)
resource Subnets 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = [for (sn, index) in snets: {
  name: snetname[index]
  parent: vnet_resource
  properties: {
    addressPrefix: snets[index]
  }
}]
