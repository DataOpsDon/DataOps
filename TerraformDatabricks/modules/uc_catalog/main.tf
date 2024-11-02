resource "databricks_catalog" "main" {
  name = var.name
  storage_root = format("abfss://%s@%s.dfs.core.windows.net",
    var.data_lake_container_name,
  var.data_lake_name)
  comment = "this catalog is managed by terraform"
}