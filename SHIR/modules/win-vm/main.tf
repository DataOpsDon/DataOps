resource "azurerm_network_interface" "main" {
  name                = var.network_interface_name
  location            = var.deployment_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "democonfigir"
    subnet_id                     = var.network_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = var.virtual_machine_name
  location              = var.deployment_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_F4s_v2"

  os_profile_windows_config {
    provision_vm_agent = true

  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "vm-admin"
    admin_password = random_password.vm_password.result

  }
}

resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "admin_user_password" {
  name         = "${var.virtual_machine_name}-admin-password"
  value        = random_password.vm_password.result
  key_vault_id = var.key_vault_id
}