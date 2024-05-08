targetScope = 'subscription'

@description('The Region for the Managed Identity.')
param location string

@description('The Resource Group for the VirtualNetwork.')
param vnetResourceGroupName string

@description('The Name for the Virtual Network.')
param vnetName string

@description('The Address Prefixes for the Virtual Network.')
param addressPrefixes string

@description('The Name of the Network Security Group.')
param nsgName string

@description('The Name of the Route Table.')
param routeTableName string

module vnetRg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'vnetRg'
  params: {
    name: vnetResourceGroupName
    location: location
  }
}

module nsg 'br/public:avm/res/network/network-security-group:0.1.3' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'nsg'
  params: {
    location: vnetRg.outputs.location
    name: nsgName
  }
}

module rt 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'rt'
  params: {
    location: vnetRg.outputs.location
    name: routeTableName
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.1.5' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'vnet'
  params: {
    addressPrefixes: [
      addressPrefixes
    ]
    name: vnetName
    location: vnetRg.outputs.location
  }
  dependsOn: [
    nsg
  ]
}

module subnets26 'subnet.bicep' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'subnets26'
  params: {
    enableNsg: true
    enableSubnetDelegation: false
    nsgName: nsgName
    routeTableName: routeTableName
    snetAdressPrefix: [for i in range(0, 2): cidrSubnet(addressPrefixes, 26, i)]
    subnetDelegation: []
    subnetNames: [
      'snet-01'
      'snet-02'
    ]
    vnetName: vnetName
  }
  dependsOn: [
    vnet
  ]
}

module subnets27 'subnet.bicep' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'subnets27'
  params: {
    enableNsg: true
    enableSubnetDelegation: false
    nsgName: nsgName
    routeTableName: routeTableName
    snetAdressPrefix: [for i in range(4, 2): cidrSubnet(addressPrefixes, 27, i)]
    subnetDelegation: []
    subnetNames: [
      'snet-03'
      'snet-04'
    ]
    vnetName: vnetName
  }
  dependsOn: [
    subnets26
    vnet
  ]
}
