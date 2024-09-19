module "metastore" {
  source                = "../../modules/uc_metastore"
  name                  = "myfirstmetastore"
  region                = "uksouth"
  databricks_account_id = var.databricks_account_id
}