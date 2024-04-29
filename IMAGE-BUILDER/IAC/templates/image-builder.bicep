@description('The name of the image builder')
param imageBuilderName string

@description('The subnet to use for the image builder')
param subnetId string

@description('The managed identity to use for the image builder')
param miId string

@description('The location to create the image builder in')
param outputLocation string

@description('The region to create the image builder in')
param region string

@description('The resource group to use for the image builder')
param stagingResourceGroupId string


var vmSize = 'Standard_D8s_v3'


param scripts array 



resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: imageBuilderName
  location: region
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${miId}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 500
    customize:  scripts
    distribute: [
      {
        location: region
        imageId: outputLocation
        runOutputName: 'WindowsServer2022Datacenter'
        type: 'ManagedImage'
      }
    ]
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    stagingResourceGroup: stagingResourceGroupId
    validate: {}
    vmProfile: {
      vmSize: vmSize
      osDiskSizeGB: 128
      vnetConfig: {
        subnetId: subnetId
        proxyVmSize: vmSize
      }
      userAssignedIdentities: [
        miId
      ]
    }
  }
}

output name string = azureImageBuilder.name
output resourceId string = azureImageBuilder.id


