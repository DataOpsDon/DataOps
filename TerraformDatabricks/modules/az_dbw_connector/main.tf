resource "azurerm_databricks_access_connector" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
  tags = {
    Environment = "Production"
  }
}