@description('This will toggle if subnet requies and NSG or not')
param enableSubnetDelegation bool

@description('This will toggle if subnet requies and NSG or not')
param enableNsg bool

@description('The list of the names of the subnets that are to be deployed')
param subnetNames array

@description('The name of the network security group that is to be associated with the subnets')
param nsgName string

@description('The list of the address prefixes of the subnets that are to be deployed')
param snetAdressPrefix array

@description('The list of the subnet delegations that are to be deployed')
param subnetDelegation array

@description('The name of the virtual network that is to be associated with the subnets')
param vnetName string

@description('The name of the route table that is to be associated with the subnets')
param routeTableName string 

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}
@batchSize(1)
resource subnets 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = [for (sn, index) in snetAdressPrefix: {
  parent: vnet
  name: subnetNames[index]
  properties: {
    addressPrefix: snetAdressPrefix[index]
    privateEndpointNetworkPolicies:(enableSubnetDelegation ? 'Disabled' : 'Enabled')
    networkSecurityGroup: {
      id: (enableNsg ? resourceId('Microsoft.Network/networkSecurityGroups', nsgName) : null)
    }
    routeTable: {
      id: resourceId('Microsoft.Network/routeTables', routeTableName)
    }
    delegations: (enableSubnetDelegation ? subnetDelegation : null)
  }
}]



