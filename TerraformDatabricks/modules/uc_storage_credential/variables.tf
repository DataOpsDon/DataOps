variable "dbw_connector_id" {
  description = "The ID of the Databricks Access Connector"
  type        = string
}

variable "name" {
  description = "The name of the storage credential"
  type        = string
}


variable "databricks_account_id" {
  type        = string
  description = "The Databricks account ID"
}