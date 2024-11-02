resource "databricks_storage_credential" "main" {
  name = var.name
  azure_managed_identity {
    access_connector_id = var.dbw_connector_id
  }
  comment = "Managed by TF"
}

