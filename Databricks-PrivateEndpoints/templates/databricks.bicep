@description('Name of the Databricks Workspace')
param workSpaceName string

@description('Name of the Managed ResourceGroup to be deployed')
param managedResourceGroup string

@description('Virtual Network to inject Databricks too')
param virtualNetworkName string

@description('Name of the Host Subnet')
param customPublicSubnetName string

@description('Name of the Container Subnet')
param customPrivateSubnetName string

var dataBricksWorkspaceSKU = 'Premium'
var deploymentLocation = 'uksouth'


resource workspaceName_resource 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: workSpaceName
  location: deploymentLocation
  sku: {
    name: dataBricksWorkspaceSKU
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroup)
    parameters: {
      customPrivateSubnetName: {
        value: customPrivateSubnetName
      }
      customPublicSubnetName: {
        value: customPublicSubnetName
      }
      customVirtualNetworkId: {
        value: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
      }

      enableNoPublicIp: {
        value: true
      }

    }

    requiredNsgRules: 'NoAzureDatabricksRules'
    publicNetworkAccess: 'Disabled'

  }
}

output workspaceName string = workspaceName_resource.name
output workspaceId string = workspaceName_resource.id
