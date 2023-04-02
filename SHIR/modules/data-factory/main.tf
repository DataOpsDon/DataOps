resource "azurerm_data_factory" "main" {
  name                            = var.data_factory_name
  location                        = var.deployment_location
  resource_group_name             = var.resource_group_name
  managed_virtual_network_enabled = true
  identity {
    type = "SystemAssigned"
  }
}
