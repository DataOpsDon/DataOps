terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.12.0"
    }
  }

}
provider "azurerm" {
  features {}
}

data "azurerm_subnet" "shir_subnet" {
  name                 = "shir-subtnet"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  depends_on = [
    azurerm_virtual_network.main
  ]
}


resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.service}-${var.environment}-01"
  location = var.deployment_location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.service}-${var.environment}-01"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/21"]

  subnet {
    name           = "shir-subtnet"
    address_prefix = "10.0.0.0/27"
  }

}

module "win_vm" {
  source                 = "../modules/win-vm"
  resource_group_name    = azurerm_resource_group.resource_group.name
  deployment_location    = azurerm_resource_group.resource_group.location
  network_interface_name = "nic-${var.service}-${var.environment}-01"
  network_subnet_id      = data.azurerm_subnet.shir_subnet.id
  virtual_machine_name   = "vm-${var.service}-${var.environment}-01"
  key_vault_id           = module.key_vault.key_vault_id
  depends_on = [
    module.key_vault,
    azurerm_virtual_network.main,
    module.data_factory
  ]
}

module "key_vault" {
  source              = "../modules/key-vault"
  resource_group_name = azurerm_resource_group.resource_group.name
  deployment_location = azurerm_resource_group.resource_group.location
  key_vault_name      = "kv-${var.service}-${var.environment}-01"
}

module "data_factory" {
  source              = "../modules/data-factory"
  resource_group_name = azurerm_resource_group.resource_group.name
  deployment_location = azurerm_resource_group.resource_group.location
  data_factory_name   = "adf-${var.service}-${var.environment}-01"
}

module "storage_account" {
  source                          = "../modules/storage-account"
  resource_group_name             = azurerm_resource_group.resource_group.name
  deployment_location             = azurerm_resource_group.resource_group.location
  storage_account_name            = "st${var.service}${var.environment}01"
  storage_account_filesystem_name = var.storage_account_filesystem_name
}













resource "azurerm_data_factory_integration_runtime_self_hosted" "adf-ir" {
  name            = "Self-Hosted-IR"
  data_factory_id = module.data_factory.data_factory_id
}





resource "azurerm_virtual_machine_extension" "self-ir-cs" {
  name                 = "self-hosted-ir-script"
  virtual_machine_id   = module.win_vm.virtual_machine_id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings             = <<SETTINGS
    {
      "fileUris": ["${azurerm_storage_blob.copy_script.url}${data.azurerm_storage_account_sas.sas_token.sas}&sr=b"],
      "commandToExecute": "powershell -executionPolicy bypass -file gatewayInstall.ps1 ${azurerm_data_factory_integration_runtime_self_hosted.adf-ir.primary_authorization_key}"
    }
SETTINGS
}

resource "azurerm_key_vault_secret" "resourceid-shir" {
  name         = "ResourceId-SelfHosted-IR"
  value        = azurerm_data_factory_integration_runtime_self_hosted.adf-ir.id
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [module.key_vault]
}

resource "azurerm_storage_blob" "copy_script" {
  name                   = "../scripts/gatewayInstall.ps1"
  storage_account_name   = module.storage_account.storage_account_name
  storage_container_name = "scripts"
  type                   = "Block"
  source                 = "../scripts/gatewayInstall.ps1"
  depends_on = [
    module.storage_account
  ]
}
output "blob_url" {
  value = azurerm_storage_blob.copy_script.url
}

data "azurerm_storage_account_sas" "sas_token" {
  connection_string = module.storage_account.storage_account_connectiong_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "15m")

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
    tag     = false
    filter  = false
  }
  depends_on = [
    azurerm_storage_blob.copy_script
  ]
}
