# Self-hosted agent VM
# Generate AGENT_COUNT VMs

resource "azurerm_public_ip" "agent_public_ip" {
  count               = var.AGENT_COUNT
  name                = "${var.PREFIX}-${var.REGION}-pip-agt${format("%02d", count.index)}-${var.ENV}"
  resource_group_name = var.RESOURCE_GROUP
  location            = var.LOCATION
  allocation_method   = "Dynamic"
  domain_name_label   = "a-${var.PREFIX}-${var.REGION}-ite-agt${format("%02d", count.index)}-${var.ENV}"
}

resource "azurerm_network_interface" "agent_nic" {
  count               = var.AGENT_COUNT
  name                = "${var.PREFIX}-${var.REGION}-nic-agt${format("%02d", count.index)}-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  ip_configuration {
    name                          = "configuration"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.sv_bas_vm_subnet.id
    public_ip_address_id          = element(azurerm_public_ip.agent_public_ip.*.id, count.index)
  }
}

resource "azurerm_network_security_group" "agent_nsg" {
  name                = "${var.PREFIX}-${var.REGION}-nsg-agent-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  security_rule {
    name                       = "default-allow-22"
    priority                   = 1000
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "agent_nsg_association" {
  count                     = var.AGENT_COUNT
  network_interface_id      = element(azurerm_network_interface.agent_nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.agent_nsg.id
}

resource "azurerm_linux_virtual_machine" "agent" {
  count                 = var.AGENT_COUNT
  name                  = "${var.PREFIX}-${var.REGION}-avm-agent-${var.ENV}-vm${format("%02d", count.index)}"
  location              = var.LOCATION
  resource_group_name   = var.RESOURCE_GROUP
  network_interface_ids = [element(azurerm_network_interface.agent_nic.*.id, count.index)]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "${var.PREFIX}-${var.REGION}-osd-agt${format("%02d", count.index)}-${var.ENV}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "agent${format("%02d", count.index)}"
  admin_username                  = var.AGENT_USERNAME
  admin_password                  = var.AGENT_PASSWORD
  disable_password_authentication = false

  # custom_data = base64encode(templatefile("../scripts/terraform/agent_init.sh", {
  #         AGENT_USERNAME      = "${var.AGENT_USERNAME}",
  #         ADO_PAT             = "${var.ADO_PAT}",
  #         ADO_ORG_SERVICE_URL = "${var.ADO_ORG_SERVICE_URL}",
  #         AGENT_POOL          = "${var.AGENT_POOL}"
  #       }))

  tags = {
    environment = "1.5"
  }
}

resource "azurerm_virtual_machine_extension" "update-vm" {
  count                = var.AGENT_COUNT
  name                 = "update-vm${format("%02d", count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  virtual_machine_id   = element(azurerm_linux_virtual_machine.agent.*.id, count.index)

  settings = <<SETTINGS
    {
        "script": "${base64encode(templatefile("../scripts/terraform/agent_init.sh", {
          AGENT_USERNAME      = "${var.AGENT_USERNAME}",
          ADO_PAT             = "${var.ADO_PAT}",
          ADO_ORG_SERVICE_URL = "${var.ADO_ORG_SERVICE_URL}",
          AGENT_POOL          = "${var.AGENT_POOL}"
        }))}"
    }
SETTINGS
}

# Schedule the shutdown schedule if needed
# timezone reference: https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/
# resource "azurerm_dev_test_global_vm_shutdown_schedule" "agent_schedule" {
#   virtual_machine_id = azurerm_linux_virtual_machine.agent.id
#   location           = var.LOCATION
#   enabled            = true

#   daily_recurrence_time = "2000"
#   timezone              = "E. Australia Standard Time"

#   notification_settings {
#     enabled = false
#   }
# }