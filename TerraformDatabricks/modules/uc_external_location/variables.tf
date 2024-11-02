variable "name" {
  type        = string
  description = "The name of the External Location"
}

variable "data_lake_name" {
  type        = string
  description = "The name of the Data Lake"
}

variable "data_lake_container_name" {
  type        = string
  description = "The name of the Data Lake container"
}

variable "databricks_account_id" {
  type        = string
  description = "The Databricks account ID"
}

variable "credential_id" {
  type        = string
  description = "The ID of the credential"
  
}