# Storage Account with VNET binding and Private Endpoint for Blob and File

resource "azurerm_storage_account" "sv_sa" {
  name                     = "${var.PREFIX}${var.REGION}strmlws${var.ENV}"
  location                 = var.LOCATION
  resource_group_name      = var.RESOURCE_GROUP
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "firewall_rules" {
  # resource_group_name  = var.RESOURCE_GROUP
  # storage_account_name = azurerm_storage_account.sv_sa.name
  storage_account_id = azurerm_storage_account.sv_sa.id

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.sv_subnet.id, azurerm_subnet.compute_subnet.id]
  bypass                     = ["AzureServices"]

  # Set network policies after Workspace has been created (will create File Share Datastore properly)
  depends_on = [azurerm_machine_learning_workspace.sv_ws]
}

# DNS Zones

resource "azurerm_private_dns_zone" "sa_zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_private_dns_zone" "sa_zone_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.RESOURCE_GROUP
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_blob"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_file_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_file"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_file.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "sa_pe_blob" {
  name                = "${var.PREFIX}-${var.REGION}-str-blob-${var.ENV}-pe"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  subnet_id           = azurerm_subnet.sv_subnet.id

  private_service_connection {
    name                           = "${var.PREFIX}-${var.REGION}-str-blob-${var.ENV}-psc"
    private_connection_resource_id = azurerm_storage_account.sv_sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "sa_pe_file" {
  name                = "${var.PREFIX}-${var.REGION}-str-file-${var.ENV}-pe"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  subnet_id           = azurerm_subnet.sv_subnet.id

  private_service_connection {
    name                           = "${var.PREFIX}-${var.REGION}-str-file-${var.ENV}-psc"
    private_connection_resource_id = azurerm_storage_account.sv_sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_zone_file.id]
  }
}
