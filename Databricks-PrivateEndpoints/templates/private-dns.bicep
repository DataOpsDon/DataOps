@description('The list of subnets to be deployed into the vnet')
param dnsZones array = [
  'privatelink.azuredatabricks.net' ]

@description('The resource Id of the Virtual Network')
param virtualNetworkId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for dnsZone in (dnsZones): {
  name: dnsZone
  location: 'global'
  properties: {}
}]

resource networkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for dnsZone in (dnsZones): {
  name: '${dnsZone}/link-to-spoke'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
  dependsOn: [
    privateDnsZone
  ]
}]
