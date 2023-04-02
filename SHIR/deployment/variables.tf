
variable "service" {
  type    = string
  default = "shir"
}

variable "environment" {
  type    = string
  default = "dev"
}
variable "deployment_location" {
  type    = string
  default = "uksouth"
}

variable "storage_account_filesystem_name" {
  type    = string
  default = "scripts"
}