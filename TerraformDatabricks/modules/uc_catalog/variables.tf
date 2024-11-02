variable "name" {
  description = "The name of the storage credential"
  type        = string
}

variable "databricks_account_id" {
  type        = string
  description = "The Databricks account ID"
}

variable "data_lake_name" {
  description = "The name of the storage account"
  type        = string
}

variable "data_lake_container_name" {
  description = "The name of the storage container"
  type        = string
}