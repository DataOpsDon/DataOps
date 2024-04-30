targetScope = 'subscription'

@description('The Subscription ID for the deployment.')
param subscriptionId string

@description('The Resource Group for the Managed Identity.')
param identityResourceGroupName string

@description('The Name for the Managed Identity.')
param managedIdentityName string

@description('The Region for the Managed Identity.')
param location string

@description('The Resource Group for the VirtualNetwork.')
param vnetResourceGroupName string

@description('The Name for the Virtual Network.')
param vnetName string

@description('The Address Prefixes for the Virtual Network.')
param addressPrefixes array

@description('The Name of the Network Security Group.')
param nsgName string

@description('The Resource Group for the Image.')
param imageResourceGroupName string

@description('The Resource Group for the Staging.')
param stagingResourceGroupName string

@description('The Name for the Image Builder')
param imageBuilderName string

@description('The Name for the Image')
param imageName string

var vmSize = 'Standard_D8s_v3'


@description('The Subnets for the Virtual Network.')
param subnets array = [
  {
    name: 'snet-image-creation'
    addressPrefix: cidrSubnet(addressPrefixes[0], 27, 1)
    privateLinkServiceNetworkPolicies: 'Disabled'
    networkSecurityGroupResourceId: resourceId(
      subscriptionId,
      vnetResourceGroupName,
      'Microsoft.Network/networkSecurityGroups',
      nsgName
    )
  }
]

module identityRg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'identityRg'
  params: {
    name: identityResourceGroupName
    location: location
  }
}

module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  scope: resourceGroup(identityResourceGroupName)
  name: 'managedIdentity'
  params: {
    name: managedIdentityName
    location: identityRg.outputs.location
  }
}

module vnetRg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'vnetRg'
  params: {
    name: vnetResourceGroupName
    location: location
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Contributor'
      }
    ]
  }
  dependsOn: [
    managedIdentity
  ]
}

module nsg 'br/public:avm/res/network/network-security-group:0.1.3' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'nsg'
  params: {
    location: vnetRg.outputs.location
    name: nsgName
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.1.5' = {
  scope: resourceGroup(vnetResourceGroupName)
  name: 'vnet'
  params: {
    addressPrefixes: addressPrefixes
    name: vnetName
    location: vnetRg.outputs.location
    subnets: subnets
  }
  dependsOn: [
    nsg
  ]
}

module imageResourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'imageResourceGroup'
  params: {
    name: imageResourceGroupName
    location: location
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Contributor'
      }
    ]
  }
  dependsOn: [
    managedIdentity
  ]
}

module stagingResourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'stagingResourceGroup'
  params: {
    name: stagingResourceGroupName
    location: location
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Owner'
      }
    ]
  }
  dependsOn: [
    managedIdentity
  ]
}


module imageBuilderAvm 'br/public:avm/res/virtual-machine-images/image-template:0.1.1' = {
  scope: resourceGroup(imageResourceGroupName)
  name: 'imageBuilderAvm'
  params: {
    name: ''
    vmUserAssignedIdentities: [
      managedIdentity.outputs.resourceId
    ]
    osDiskSizeGB: 128
    vmSize: vmSize
    stagingResourceGroup: stagingResourceGroup.outputs.resourceId
    subnetResourceId: vnet.outputs.subnetResourceIds[0]
    customizationSteps: scripts
    distributions: [
      {
        type: 'ManagedImage'
        imageResourceId: '/subscriptions/${subscriptionId}/resourceGroups/${imageResourceGroupName}/providers/Microsoft.Compute/images/${imageName}'
        runOutputName: 'WindowsServer2022Datacenter'
        location: location
        imageName: imageName
      }
    ]
    imageSource: {}
    managedIdentities: {
      userAssignedResourceIds: [
        managedIdentity.outputs.resourceId
      
      ]
    }
  }
}

param scripts array = [
  {
    type: 'PowerShell'
    runElevated: true
    name: 'Install Chocolatey'
    inline: [
      '[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor "Tls12"'
      'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(https://chocolatey.org/install.ps1))'
    ]
  }
  {
    type: 'PowerShell'
    runElevated: true
    name: 'Install Azure CLI'
    inline: [
      'choco install azure-cli -y'
    ]
  }
  {
    type: 'WindowsRestart'
    name: 'Restart'
    restartTimeout: '15m'
    restartCheckCommand: 'echo "Restarted"'
  }
  {
    type: 'PowerShell'
    runElevated: true
    name: 'Install Az Powershell Modules'
    inline: [
      'choco install az.powershell -y'
    ]
  }
  {
    type: 'WindowsRestart'
    name: 'Restart'
    restartTimeout: '15m'
    restartCheckCommand: 'echo "Restarted"'
  }
  {
    type: 'PowerShell'
    name: 'Install Az Powershell Modules'
    inline: [
      'choco install powershell-core -y'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Install VS Build Tools'
    inline: [
      'choco install visualstudio2022buildtools -y'
    ]
  }
  {
    type: 'PowerShell'
    name: 'Install VS Build Tools'
    inline: [
      'choco install sqlpackage -y'
    ]
  }
]

module identityRgRa 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'identityRgRa'
  params: {
    name: identityResourceGroupName
    location: location
    roleAssignments: [
      {
        principalId: managedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Contributor'
      }
    ]
  }
  dependsOn: [
    managedIdentity
  ]
}
