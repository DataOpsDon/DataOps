resource "databricks_metastore_assignment" "main" {
  provider             = databricks.accounts
  workspace_id         = var.workspace_id
  metastore_id         = var.metastore_id
}