@description('Name of the NSG for the spoke VNET')
param spokeNsgName string = 'nsg-spoke-01'

@description('Name of the NSG for the hub VNET')
param hubNsgName string

@description('Name of the hub VNET')
param vnetHubName string = 'vnetHub-01'

@description('Name of the spoke VNET')
param vnetSpokeName string = 'vnetSpoke-01'

@description('Name of the Databricks workspace for the spoke VNET')
param databricksSpokeName string = 'db-spoke-01'

@description('Name of the Databricks workspace for the hub VNET')
param databricksHubName string = 'db-hub-01'

@description('Name of the private DNS zone for Databricks')
param databricksPrivateDnsZone string = 'privatelink.databricks.azure.com'

@description('Array of private DNS zones to be created')
param dnsZones array = [

  databricksPrivateDnsZone

]

@description('Address space for the hub VNET')
param vnetHubAddressSpace string = '10.0.0.0/24'

@description('Address space for the spoke VNET')
param vnetSpokeAddressSpace string = '10.0.1.0/24'

var privateSubnetName = 'snet1'
var publicSubnetName = 'snet2'
var userInterfaceSnet = 'snet3'
var browserAuthenticationSnet = 'snet4'
var deploymentLocation = 'uksouth'

module vnetHub 'templates/network.bicep' = {
  name: 'vnetHub'
  params: {
    location: deploymentLocation
    addressSpace: vnetHubAddressSpace
    vnetName: vnetHubName
    nsgName: hubNsgName
  }

}

module vnetSpoke 'templates/network.bicep' = {
  name: 'vnetSpoke'
  params: {
    location: deploymentLocation
    addressSpace: vnetSpokeAddressSpace
    vnetName: vnetSpokeName
    nsgName: spokeNsgName
  }
}

module databricksDns 'templates/private-dns.bicep' = {
  name: 'bricksDns'
  params: {
    virtualNetworkId: resourceId('Microsoft.Network/virtualNetworks', vnetHubName)
    dnsZones: dnsZones
  }
  dependsOn: [
    vnetHub
  ]
}

module bricksHub 'templates/databricks.bicep' = {
  name: 'bricksHub'
  params: {
    customPrivateSubnetName: privateSubnetName
    customPublicSubnetName: publicSubnetName
    managedResourceGroup: 'rg-${databricksHubName}'
    virtualNetworkName: vnetHubName
    workSpaceName: databricksHubName
  }
  dependsOn: [
    vnetHub
  ]
}
// Deploy Browser Authentication Private Endpoints for Hub VNET
resource privateEndpointsDatabricks 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: 'pe-ba-${databricksHubName}'
  location: deploymentLocation
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHubName, browserAuthenticationSnet)
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-ba-${databricksHubName}'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Databricks/workspaces', databricksHubName)
          groupIds: [
            'browser_authentication'
          ]
        }

      }
    ]
  }
  dependsOn: [
    bricksHub
    vnetHub
  ]
}
// Associate Private DNS Zone to Private Endpoint
resource privateDNSZoneMetadata 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointsDatabricks
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: databricksPrivateDnsZone
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones/', databricksPrivateDnsZone)
        }
      }
    ]
  }
}

// Deploy Databricks Spoke
module bricksSpoke 'templates/databricks.bicep' = {
  name: 'bricksSpoke'
  params: {
    customPrivateSubnetName: privateSubnetName
    customPublicSubnetName: publicSubnetName
    managedResourceGroup: 'rg-${databricksSpokeName}'
    virtualNetworkName: vnetSpokeName
    workSpaceName: databricksSpokeName
  }
  dependsOn: [
    vnetSpoke
    vnetHub
  ]
}

// Deploy Private Endpoints for Spoke VNET
resource privateEndpointsDatabricksSpoke_1 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: 'pe-ui-ba-${databricksSpokeName}'
  location: deploymentLocation
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetSpokeName, userInterfaceSnet)
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-db-spoke-ui-ba-01'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Databricks/workspaces', databricksSpokeName)
          groupIds: [
            'databricks_ui_api'
          ]
        }
      }

    ]
  }
  dependsOn: [
    bricksSpoke
    vnetSpoke
  ]
}

// Associate Private DNS Zone to Private Endpoint
resource privateDNSZoneMetadataKeyVault_2 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointsDatabricksSpoke_1
  name: 'default_1'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: databricksPrivateDnsZone
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones/', databricksPrivateDnsZone)
        }
      }
    ]
  }
}

// Deploy Private Endpoint for Hub VNET
resource privateEndpointsDatabricksHub 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: 'pe-ui-fe-${databricksSpokeName}'
  location: deploymentLocation
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHubName, userInterfaceSnet)
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-ui-${databricksSpokeName}'
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Databricks/workspaces', databricksHubName)
          groupIds: [
            'databricks_ui_api'
          ]
        }
      }

    ]
  }
  dependsOn: [
    bricksHub
    vnetHub
    privateEndpointsDatabricks
  ]
}
// Associate Private DNS Zone to Private Endpoint
resource privateDNSZoneMetadataKeyVault_3 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  parent: privateEndpointsDatabricksHub
  name: 'default_2'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: databricksPrivateDnsZone
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones/', databricksPrivateDnsZone)
        }
      }
    ]
  }
}


// Deploy Private Endpoint for Hub VNET
resource sourceToDestinationPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${vnetHubName}to${vnetSpokeName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetSpokeName)
    }
    peeringState: 'Connected'

  }
  dependsOn: [
    vnetHub
    vnetSpoke
  ]
}

// Deploy Private Endpoint for Spoke VNET
resource sourceToDestinationPeering_Spoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${vnetSpokeName}to${vnetHubName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetHubName)
    }
    peeringState: 'Connected'

  }
  dependsOn: [
    vnetHub
    vnetSpoke
    sourceToDestinationPeering
  ]
}
