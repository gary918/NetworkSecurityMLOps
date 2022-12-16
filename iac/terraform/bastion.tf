# Azure Bastion within AzureBastionSubnet

resource "azurerm_public_ip" "bastion_ip" {
  name                = "${var.PREFIX}-${var.REGION}-pip-bastn-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "jumphost_bastion" {
  name                = "${var.PREFIX}-${var.REGION}-bas-jmpht-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}