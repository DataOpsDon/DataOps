module "metastore" {
  source                = "../../modules/uc_metastore"
  name                  = var.region
  region                = "uksouth"
  databricks_account_id = var.databricks_account_id
  providers = {
    databricks = databricks.accounts
  }
}

module "avm-res-resources-resourcegroup" {
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.1.0"
  location = var.region
  name     = "rg-uc-dev-uks-001"
}

module "avm-res-storage-storageaccount" {
  source                        = "Azure/avm-res-storage-storageaccount/azurerm"
  version                       = "0.2.7"
  name                          = "stagucdevuks001"
  shared_access_key_enabled     = true
  public_network_access_enabled = true
  is_hns_enabled                = true
  network_rules = ({
    default_action = "Allow"
    bypass         = ["AzureServices"]
    ip_rules       = []
  })
  resource_group_name           = module.avm-res-resources-resourcegroup.name
  location                      = module.avm-res-resources-resourcegroup.resource.location
  containers = {
    "datalake" = {
      "name"        = "data-lake"
      "access_type" = "private"
    }
    "unity_catalog" = {
      "name"        = "unity-catalog"
      "access_type" = "private"
    }
  }
  role_assignments =  {
    "storage" = {
      "role_definition_id_or_name" = "Storage Blob Data Contributor"
      "principal_id"         = module.avm-res-databricks-workspace.databricks_access_connector_principal_ids["connect"]
    }
  }
  depends_on = [module.avm-res-resources-resourcegroup]
}


module "avm-res-databricks-workspace" {
  source              = "Azure/avm-res-databricks-workspace/azurerm"
  version             = "0.2.0"
  name                = "dbw-uc-dev-uks-001"
  sku                 = "premium"
  resource_group_name = module.avm-res-resources-resourcegroup.name
  location            = module.avm-res-resources-resourcegroup.resource.location
  access_connector = {
    "connect" = {
      name                = "dbwac-uc-dev-uks-001"
      resource_group_name = module.avm-res-resources-resourcegroup.name
      location            = module.avm-res-resources-resourcegroup.resource.location
      identity = ({
        type = "SystemAssigned"
      })
    }
  }
  depends_on = [module.avm-res-resources-resourcegroup]
}

module "metastore_assignmnet" {
  source                = "../../modules/uc_metastore_assignment"
  workspace_id          = module.avm-res-databricks-workspace.databricks_workspace_id
  metastore_id          = module.metastore.id
  databricks_account_id = var.databricks_account_id
  providers = {
    databricks = databricks.accounts
  }
}


module "uc_storage_credential" {
  source                = "../../modules/uc_storage_credential"
  name                  = "uc-storage-credential"
  dbw_connector_id      = module.avm-res-databricks-workspace.databricks_access_connector_ids["connect"]
  databricks_account_id = var.databricks_account_id
  providers = {
    databricks = databricks.workspace
  }
}



module "uc_external_location" {
  source                   = "../../modules/uc_external_location"
  name                     = "uc-external-location"
  data_lake_name           = module.avm-res-storage-storageaccount.name
  data_lake_container_name = module.avm-res-storage-storageaccount.containers["datalake"].name
  databricks_account_id    = var.databricks_account_id
  credential_id            = module.uc_storage_credential.id
  providers = {
    databricks = databricks.workspace
  }
}

module "catalog" {
  source = "../../modules/uc_catalog" 
  name = "dev-catalog"
  data_lake_name           = module.avm-res-storage-storageaccount.name
  data_lake_container_name = module.avm-res-storage-storageaccount.containers["datalake"].name
  databricks_account_id = var.databricks_account_id
  providers = {
    databricks = databricks.workspace
  }
}

