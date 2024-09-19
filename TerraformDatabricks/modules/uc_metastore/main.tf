resource "databricks_metastore" "main" {
  provider      = databricks.accounts
  name          = var.name
  force_destroy = true
  region        = var.region
}