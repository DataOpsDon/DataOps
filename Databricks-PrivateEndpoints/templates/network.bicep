@description('The location of the Virtual Network')
@allowed([
  'uksouth'
  'ukswest' ])
param location string = 'uksouth'

@description('The address space of the Virtual Network')
param addressSpace string

@description('The name of the Virtual Network')
param vnetName string

@description('The number of subnets to create')
param itemCount int = 5

//Calculate the subnets
var snets26 = [for i in range(0, 2): cidrSubnet(addressSpace, 26, i)]
var snets28 = [for i in range(8, 3): cidrSubnet(addressSpace, 28, i)]

//Create the subnet names
var snetArray = [for i in range(0, itemCount): 'snet${(i + 1)}']
var snetArray28 = [for i in range(2, itemCount): 'snet${(i + 1)}']

param nsgName string

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
  dependsOn: [
    nsg
  ]
}

@batchSize(1)
resource Subnets 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = [for (sn, index) in snets26: {
  name: snetArray[index]
  parent: vnet_resource
  properties: {
    addressPrefix: snets26[index]
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
    }
    delegations: [
      {
        name: 'Microsoft.Databricks.workspaces'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
}]

@batchSize(1)
resource Subnets28 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = [for (sn, index) in snets28: {
  name: snetArray28[index]
  parent: vnet_resource
  properties: {
    addressPrefix: snets28[index]
  }
  dependsOn: [
    Subnets
  ]
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Databricks-Workspace-Port-443'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow Databricks Workspace'
        }

      }
      {
        name: 'Allow-Databricks-Workspace-Port-6666'
        properties: {
          priority: 205
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '6666'
          description: 'Allow Databricks Workspace'
        }

      }
    ]
  }

}
