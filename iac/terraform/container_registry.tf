# Azure Container Registry

# Public ACR for storing images for IoT Edge
resource "azurerm_container_registry" "sv_acr_img" {
  name                     = "${var.PREFIX}${var.REGION}acrimg${var.ENV}"
  resource_group_name      = var.RESOURCE_GROUP
  location                 = var.LOCATION
  sku                      = "Premium"
  admin_enabled            = true
}

# AML ACR is for private access by AML WS
resource "azurerm_container_registry" "sv_acr_aml" {
  name                     = "${var.PREFIX}${var.REGION}acraml${var.ENV}"
  resource_group_name      = var.RESOURCE_GROUP
  location                 = var.LOCATION
  sku                      = "Premium"
  admin_enabled            = true
  public_network_access_enabled = false
}

resource "azurerm_private_dns_zone" "app_acr_zone" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_acr_zone_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_app_acr"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.app_acr_zone.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

resource "azurerm_private_endpoint" "sv_acr_aml_ep" {
  name                = "${var.PREFIX}-${var.REGION}-acr-app-${var.ENV}-pe"
  resource_group_name = var.RESOURCE_GROUP
  location            = var.LOCATION
  subnet_id           = azurerm_subnet.sv_subnet.id

  private_service_connection {
    name                           = "${var.PREFIX}-${var.REGION}-acr-app-${var.ENV}-psc"
    private_connection_resource_id = azurerm_container_registry.sv_acr_aml.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-app-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_acr_zone.id]
  }
}