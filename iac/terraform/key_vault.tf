# Key Vault with VNET binding and Private Endpoint

resource "azurerm_key_vault" "sv_kv" {
  name                = "${var.PREFIX}-${var.REGION}-kvt-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = [azurerm_subnet.sv_subnet.id, azurerm_subnet.compute_subnet.id]
    bypass         = "AzureServices"
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "kv_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.RESOURCE_GROUP
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_kv"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.PREFIX}-${var.REGION}-kvt-${var.ENV}-pe"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  subnet_id           = azurerm_subnet.sv_subnet.id

  private_service_connection {
    name                           = "${var.PREFIX}-${var.REGION}-kvt-${var.ENV}-psc"
    private_connection_resource_id = azurerm_key_vault.sv_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_zone.id]
  }
}


resource "azurerm_key_vault_access_policy" "sv_kv" {
  key_vault_id = azurerm_key_vault.sv_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get", "get", "list", "delete", "purge"
  ]

  secret_permissions = [
    "backup", "get", "set", "list", "delete", "purge", "recover", "restore"
  ]
}