output "data_factory_id" {
  value = azurerm_data_factory.main.id
}

output "data_factory_principal_id" {
  value = azurerm_data_factory.main.identity[0].principal_id
}