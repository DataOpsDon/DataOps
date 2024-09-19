terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "1.51.0"
    }
  }
}
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}