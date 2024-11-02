resource "databricks_external_location" "main" {
  name = "external"
  url = format("abfss://%s@%s.dfs.core.windows.net",
    var.data_lake_container_name,
  var.data_lake_name)

  credential_name = var.credential_id
  comment         = "Managed by TF"
}