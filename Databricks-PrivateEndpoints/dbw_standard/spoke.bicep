targetScope = 'subscription'

@description('Required. The name of the resource group.')
param resourceGroupName string 

param databricksManagedResourceGroupName string

@description('Required. Location for all resources.')
param location string 

@description('Required. The address prefix for the subnet.')
param addressPrefix string

@description('Required. The address prefix for the subnet.')
param environment string

@description('The default network security group resource id.')
param defaultNetworkSecurityGroupId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/networkSecurityGroups','nsg-dbw-spoke-uks-${environment}-01')

@description('The databricks network security group resource id.')
param databricksNsgResourceId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/networkSecurityGroups', 'nsg-dbw-spoke-uks-${environment}-02')

@description('The databricks route table resource id.')
param databricksRouteTableResourceId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/routeTables', 'rt-dbw-spoke-uks-${environment}-02')

var hubSubnetId = resourceId(subscriptionId, hubResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets',hubVnetName ,'snet-pe-uks-${environment}-01')

var hubResourceGroupName = 'rg-dbw-hub-uks-${environment}-01'
var hubVnetName = 'vnet-dbw-hub-uks-${environment}-01'

var privateDnsZoneResourceId = resourceId(subscriptionId, hubResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azuredatabricks.net')
var hubVnetId = resourceId(subscriptionId, hubResourceGroupName, 'Microsoft.Network/virtualNetworks', hubVnetName)


@description('SubscriptionId.')
param subscriptionId string = subscription().subscriptionId
var resourceNames = {
  databricksWorkspaceNetworkSecurityGroup:        '${namingModule.outputs.nsgName}-02'
  databricksWorkspaceRouteTable:                  '${namingModule.outputs.routeTableName}-02'
  defaultNetworkSecurityGroup:                    '${namingModule.outputs.nsgName}-01'
  defaultRouteTable:                              '${namingModule.outputs.routeTableName}-01'
  virtualNetwork:                                 '${namingModule.outputs.vnetName}-01'
  virtualMachineScaleSet:                         '${namingModule.outputs.vmssName}-01'
  storageAccount:                                 '${namingModule.outputs.storageAccountName}01'
  databricks:                                     '${namingModule.outputs.databricksName}-01'
}

module rg 'br/public:avm/res/resources/resource-group:0.2.4' = {
  name: 'rg'
  params: {
    name: resourceGroupName
    location: location
  }
}

module pdnsZone 'br/public:avm/res/network/private-dns-zone:0.4.0' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'pdnsZone'
  params: {
    name: 'privatelink.azuredatabricks.net'
     virtualNetworkLinks: [
    
     ]
  }
}

module namingModule 'naming-module.bicep' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'network'
  params: {
    environment: environment
    region: 'uks'
    workload: 'dbw-spoke'
  }
  dependsOn: [
    rg
  ]
}

@description('Required. An Array of subnets to deploy to the Virtual Network.')
var subnets  = [
  {
    addressPrefix: cidrSubnet(addressPrefix, 26, 0)
    name: 'snet-dbw-spoke-public-uks-${environment}-01'
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Enabled'
    routeTableResourceId: databricksRouteTableResourceId
    networkSecurityGroupResourceId: databricksNsgResourceId
    delegations: [
      {
        name: 'Microsoft.Databricks/workspaces'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
  {
    addressPrefix: cidrSubnet(addressPrefix, 26, 1)
    name: 'snet-dbw-spoke-private-uks-${environment}-01'
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Enabled'
    routeTableResourceId: databricksRouteTableResourceId
    networkSecurityGroupResourceId: databricksNsgResourceId
    delegations: [
      {
        name: 'Microsoft.Databricks/workspaces'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
  {
    addressPrefix: cidrSubnet(addressPrefix, 27, 4)
    name: 'snet-pe-uks-${environment}-01'
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Enabled'
    networkSecurityGroupResourceId: defaultNetworkSecurityGroupId
    delegations: []
  }
]

module databricksWorkspaceRouteTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'databricksWorkspaceRouteTable'
  params: {
    name: resourceNames.databricksWorkspaceRouteTable
    location: location
    routes: databricksWorkspaceRouteTableRoutes
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

module databricksWorkspaceNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.2.0' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'databricksWorkspaceNetworkSecurityGroup'
  params: {
    name: resourceNames.databricksWorkspaceNetworkSecurityGroup
    location: location
    tags: tags
    securityRules: dbrNsgRules
  }
  dependsOn: [
    rg
  ]
}
module defaultNsg 'br/public:avm/res/network/network-security-group:0.2.0' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'defaultNsg'
  params: {
    name: resourceNames.defaultNetworkSecurityGroup
    location: location
    tags: tags
    securityRules: defaultNsgRule
  }
  dependsOn: [
    rg
  ]
}


module vnet 'br:mcr.microsoft.com/bicep/avm/res/network/virtual-network:0.1.8' =  {
  scope: az.resourceGroup(resourceGroupName)
  name: 'vnet' 
  params: {
    name: resourceNames.virtualNetwork
    addressPrefixes: [addressPrefix]
    subnets: subnets
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'hub-spoke'
        remoteVirtualNetworkId: hubVnetId
        useRemoteGateways: false
      }
    ]
  }
  dependsOn: [
    rg
    databricksWorkspaceNetworkSecurityGroup
    databricksWorkspaceRouteTable
    defaultNsg
  ]
}



var tags = {
  'Business Domain': 'spoke'
  'Business Service Name': 'HESP'
}

var databricksWorkspaceRouteTableRoutes  = [
  {
    name: 'adb-servicetag'
    properties: {
      addressPrefix: 'AzureDatabricks'
      nextHopType: 'Internet'
      nextHopIpAddress: ''
    }
  }
  {
    name: 'adb-metastore'
    properties: {
      addressPrefix: 'Sql.WestEurope'
      nextHopType: 'Internet'
      nextHopIpAddress: ''
    }
  }
  {
    name: 'adb-storage'
    properties: {
      addressPrefix: 'Storage.WestEurope'
      nextHopType: 'Internet'
      nextHopIpAddress: ''
    }
  }
]

var dbrNsgRules = [
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
    properties: {
      description: 'Required for worker nodes communication within a cluster.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      direction: 'Inbound'
      priority: 100
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
    properties: {
      description: 'Required for worker nodes communication within a cluster.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      direction: 'Outbound'
      priority: 100
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
    properties: {
      description: 'Required for workers communication with Azure SQL services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3306'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Sql'
      access: 'Allow'
      direction: 'Outbound'
      priority: 101
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
    properties: {
      description: 'Required for workers communication with Azure Storage services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Storage'
      access: 'Allow'
      direction: 'Outbound'
      priority: 102
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
    properties: {
      description: 'Required for worker communication with Azure EventHb services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '9093'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'EventHub'
      access: 'Allow'
      direction: 'Outbound'
      priority: 103
      sourcePortRanges: []
      destinationPortRanges: []
      sourceAddressPrefixes: []
      destinationAddressPrefixes: []
    }
  }
  
]

var defaultNsgRule = [
  
]

module databricksWorkspace 'br/public:avm/res/databricks/workspace:0.4.0'= {
  scope: az.resourceGroup(resourceGroupName)
  name: 'databricksWorkspace'
  params: {
    name: resourceNames.databricks
    location: rg.outputs.location
    tags: tags
    skuName: 'premium'
    managedResourceGroupResourceId: az.subscriptionResourceId(subscriptionId, 'Microsoft.Resources/resourceGroups', databricksManagedResourceGroupName)
    requireInfrastructureEncryption: true
    publicNetworkAccess: 'Disabled'
    requiredNsgRules: 'NoAzureDatabricksRules'
    roleAssignments: [
    ]
    disablePublicIp: true
    customPrivateSubnetName: vnet.outputs.subnetNames[1]
    customPublicSubnetName: vnet.outputs.subnetNames[0]
    customVirtualNetworkResourceId: vnet.outputs.resourceId
    diagnosticSettings: [
    ]
  }
  dependsOn: [
    rg
  ]
}





module databricksWorkspaceBEPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'databricksWorkspaceBEPrivateEndpoint'
  params: {
    name: 'pe-be-${resourceNames.databricks}'
    subnetResourceId: vnet.outputs.subnetResourceIds[2]
    privateDnsZoneResourceIds: [
      privateDnsZoneResourceId
    ]
    privateLinkServiceConnections: [
      {
       name: 'pe-be-${databricksWorkspace.outputs.name}'
       properties: {
        groupIds: ['databricks_ui_api']
        privateLinkServiceId: databricksWorkspace.outputs.resourceId
         
       }
        
      }
    ]
  }
  dependsOn: [
    rg
    databricksWorkspace
  ]
}
