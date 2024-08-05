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
param defaultNetworkSecurityGroupId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/networkSecurityGroups','nsg-dbw-hub-uks-${environment}-01')

@description('The databricks network security group resource id.')
param databricksNsgResourceId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/networkSecurityGroups', 'nsg-dbw-hub-uks-${environment}-02')

@description('The databricks route table resource id.')
param databricksRouteTableResourceId string = resourceId(subscriptionId, resourceGroupName,'Microsoft.Network/routeTables', 'rt-dbw-hub-uks-${environment}-02')

@secure()
param vmPassword string


@description('SubscriptionId.')
param subscriptionId string = subscription().subscriptionId
var resourceNames = {
  bastionNetworkSecurityGroup:                   '${namingModule.outputs.nsgName}-03'
  databricksWorkspaceNetworkSecurityGroup:        '${namingModule.outputs.nsgName}-02'
  databricksWorkspaceRouteTable:                  '${namingModule.outputs.routeTableName}-02'
  defaultNetworkSecurityGroup:                    '${namingModule.outputs.nsgName}-01'
  defaultRouteTable:                              '${namingModule.outputs.routeTableName}-01'
  virtualNetwork:                                 '${namingModule.outputs.vnetName}-01'
  virtualMachineScaleSet:                         '${namingModule.outputs.vmssName}-01'
  storageAccount:                                 '${namingModule.outputs.storageAccountName}01'
  bastionHost:                                    '${namingModule.outputs.bastionName}-01'
  databricks:                                     '${namingModule.outputs.databricksName}-01'
  virtualMachine:                                 '${namingModule.outputs.vmName}01'
  keyVault:                                       '${namingModule.outputs.keyVaultName}-01'
}

module rg 'br/public:avm/res/resources/resource-group:0.2.4' = {
  name: 'rg'
  params: {
    name: resourceGroupName
    location: location
    
  }
}

module namingModule 'naming-module.bicep' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'network'
  params: {
    environment: environment
    region: 'uks'
    workload: 'dbw-hub'
  }
  dependsOn: [
    rg
  ]
}


var imageReference = {
  publisher:                                          'MicrosoftWindowsServer'
  offer:                                              'WindowsServer'
  sku:                                                '2022-datacenter-azure-edition-hotpatch'
  version:                                            'latest'
}


var vmConfig = {
  diskSizeGB:                                         128
  deploymentName:                                     'vm-ir'
  size:                                               'standard_d4s_v3'
  adminUsername:                                      'admin-ir'
}

@description('Required. An Array of subnets to deploy to the Virtual Network.')
var subnets  = [
  {
    addressPrefix: cidrSubnet(addressPrefix, 26, 0)
    name: 'AzureBastionSubnet'
    privateLinkServiceNetworkPolicies: 'Enabled'
    privateEndpointNetworkPolicies: 'Enabled'
    networkSecurityGroupResourceId: bastionNsg.outputs.resourceId 
    delegations: []

  }
  {
    addressPrefix: cidrSubnet(addressPrefix, 26, 1)
    name: 'snet-dbw-hub-public-uks-${environment}-01'
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
    addressPrefix: cidrSubnet(addressPrefix, 26, 2)
    name: 'snet-dbw-hub-private-uks-${environment}-01'
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
    addressPrefix: cidrSubnet(addressPrefix, 27, 6)
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
module bastionNsg 'br/public:avm/res/network/network-security-group:0.2.0' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'bastionNsg'
  params: {
    name: resourceNames.bastionNetworkSecurityGroup
    location: location
    tags: tags
    securityRules: bastionNsgRules
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
    securityRules: defaultNsgRules
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
  }
  dependsOn: [
    rg
    databricksWorkspaceNetworkSecurityGroup
    databricksWorkspaceRouteTable
    bastionNsg
    defaultNsg
  ]
}

module bastion 'br/public:avm/res/network/bastion-host:0.2.2' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'bastion'
  params: {
    name: resourceNames.bastionHost
    virtualNetworkResourceId: vnet.outputs.resourceId
  }
}

var tags = {
  'Business Domain': 'Hub'
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
      description: 'Required for worker communication with Azure Eventhub services.'
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

var bastionNsgRules = [
  {
    name: 'AllowHttpsInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowGatewayManagerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'GatewayManager'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowLoadBalancerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationInBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'DenyAllInBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 1000
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowSshRdpOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRanges: [
        '22'
        '3389'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowAzureCloudCommunicationOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '443'
      destinationAddressPrefix: 'AzureCloud'
      access: 'Allow'
      priority: 110
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowGetSessionInformationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRanges: [
        '80'
        '443'
      ]
      access: 'Allow'
      priority: 130
      direction: 'Outbound'
    }
  }
  {
    name: 'DenyAllOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Deny'
      priority: 1000
      direction: 'Outbound'
    }
  }
]


var defaultNsgRules = []

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
    customPrivateSubnetName: vnet.outputs.subnetNames[2]
    customPublicSubnetName: vnet.outputs.subnetNames[1]
    customVirtualNetworkResourceId: vnet.outputs.resourceId
    diagnosticSettings: [
    ]
  }
  dependsOn: [
    rg
  ]
}

module pdnsZone 'br/public:avm/res/network/private-dns-zone:0.4.0' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'pdnsZone'
  params: {
    name: 'privatelink.azuredatabricks.net'
     virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.outputs.resourceId
      }
     ]
  }
}

module databricksWorkspaceBAPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  scope: az.resourceGroup(resourceGroupName)
  name: 'databricksWorkspaceBAPrivateEndpoint'
  params: {
    name: 'pe-ba-${resourceNames.databricks}'
    subnetResourceId: vnet.outputs.subnetResourceIds[3]
    privateDnsZoneResourceIds: [
      pdnsZone.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
       name: 'pe-ba-${databricksWorkspace.outputs.name}'
       properties: {
         groupIds: ['browser_authentication']
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

param integrationRuntimeVmCount int = 1

module vmIR 'br/public:avm/res/compute/virtual-machine:0.4.2' =  [
  for i in range(0, integrationRuntimeVmCount):{
    scope: az.resourceGroup(resourceGroupName)
    name: '${vmConfig.deploymentName}${i + 1}${guid(resourceGroupName)}'
    params: {
  
      
      managedIdentities: {
        systemAssigned: true
      }
      location:  location
      computerName: 'vmir${environment}${i + 1}'
      encryptionAtHost: false
      adminUsername: vmConfig.adminUsername
      adminPassword:  vmPassword
      imageReference: imageReference
      name: '${resourceNames.virtualMachine}${i +1}'
      nicConfigurations: [
        {

          ipConfigurations: [
            {
              name: 'ipconfig01'

  
              subnetResourceId: vnet.outputs.subnetResourceIds[3]
            }

          ]
          nicSuffix: ''
        }
        
      ]
      osDisk: {
        diskSizeGB: vmConfig.diskSizeGB
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'

        }
        name: 'osdisk-${resourceNames.virtualMachine}${i + 1}'
      }
      osType: 'Windows'
      vmSize: vmConfig.size
      zone: int(i % 3 == 0 ? 3 : i % 3)
    }
  dependsOn: [
  
  ]
  
  }
]
