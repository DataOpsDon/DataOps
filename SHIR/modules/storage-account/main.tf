
resource "azurerm_storage_account" "main" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.deployment_location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = false
  large_file_share_enabled        = true
  allow_nested_items_to_be_public = false


}

resource "azurerm_storage_container" "main" {
  name                  = var.storage_account_filesystem_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}