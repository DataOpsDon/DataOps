output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_connectiong_string" {
  value = azurerm_storage_account.main.primary_blob_connection_string
}