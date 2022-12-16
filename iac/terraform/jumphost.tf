# Jump host for testing VNET and Private Link

resource "azurerm_network_interface" "jumphost_nic" {
  name                = "${var.PREFIX}-${var.REGION}-nic-jmpht-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  ip_configuration {
    name                          = "configuration"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.sv_bas_vm_subnet.id
    # public_ip_address_id          = azurerm_public_ip.jumphost_public_ip.id
  }
}

resource "azurerm_network_security_group" "jumphost_nsg" {
  name                = "${var.PREFIX}-${var.REGION}-nsg-jmpht-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  security_rule {
    name                       = "RDP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jumphost_nsg_association" {
  network_interface_id      = azurerm_network_interface.jumphost_nic.id
  network_security_group_id = azurerm_network_security_group.jumphost_nsg.id
}

resource "azurerm_virtual_machine" "jumphost" {
  name                  = "${var.PREFIX}-${var.REGION}-avm-jmpht-${var.ENV}-vm01"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  network_interface_ids = [azurerm_network_interface.jumphost_nic.id]
  vm_size               = "Standard_DS3_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-win-2019"
    sku       = "server-2019"
    version   = "latest"
  }

  os_profile {
    computer_name  = "jumphost"
    admin_username = var.JUMPHOST_USERNAME
    admin_password = var.JUMPHOST_PASSWORD
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-${var.REGION}-osd-jmpht-${var.ENV}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
}

# timezone reference: https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
resource "azurerm_dev_test_global_vm_shutdown_schedule" "jumphost_schedule" {
  virtual_machine_id = azurerm_virtual_machine.jumphost.id
  location           = var.LOCATION
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "E. Australia Standard Time"

  notification_settings {
    enabled = false
  }
}
