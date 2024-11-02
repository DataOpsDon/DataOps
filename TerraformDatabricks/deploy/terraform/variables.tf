variable "databricks_account_id" {
  type        = string
  description = "The Databricks account ID"
}

variable "region" {
  type        = string
  description = "The Azure region to deploy the resources"
  default     = "uksouth"
}