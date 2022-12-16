# Virtual Network definition

# Virtual network for AML workspac, Azure Function etc. 
resource "azurerm_virtual_network" "sv_vnet" {
  name                = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet21"
  address_space       = ["10.21.0.0/16"]
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_subnet" "sv_subnet" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet21-sn01"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_vnet.name
  address_prefixes     = ["10.21.1.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}


resource "azurerm_subnet" "compute_subnet" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet21-sn02"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_vnet.name
  address_prefixes     = ["10.21.2.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  enforce_private_link_service_network_policies = true
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_security_group" "nsg_compute_subnet" {
  name                = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet21-sn02-nsg"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP

  security_rule {
    name                       = "BatchNodeManagement_29876_29877"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29876-29877"
    source_address_prefix      = "BatchNodeManagement"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "JupyterServerPort"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "44224"
    source_address_prefix      = "AzureMachineLearning"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowCorpnet"
    priority                   = 2700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "CorpNetPublic"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowSAW"
    priority                   = 2701
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_compute_subnet" {
  subnet_id                 = azurerm_subnet.compute_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_compute_subnet.id
}

resource "azurerm_subnet" "vpn_gateway_subnet" {
  name                 = "GatewaySubnet"  #Default gateway subnet0
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_vnet.name
  address_prefixes     = ["10.21.7.0/24"]
}

# Virtual network for Azure Bastion, self-hosted agent
resource "azurerm_virtual_network" "sv_bas_vnet" {
  name                = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet23"
  address_space       = ["10.23.0.0/16"]
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_subnet" "sv_bas_vm_subnet" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet23-sn01"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_bas_vnet.name
  address_prefixes     = ["10.23.1.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault", "Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_bas_vnet.name
  address_prefixes     = ["10.23.10.0/27"]
}

# Virtual network for Azure Container Registry
resource "azurerm_virtual_network" "sv_app_vnet" {
  name                = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet24"
  address_space       = ["10.24.0.0/16"]
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_subnet" "fun_subnet" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet24-sn01"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_app_vnet.name
  address_prefixes     = ["10.24.1.0/24"]
  service_endpoints    = ["Microsoft.Web"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "fun_subnet_vnet_integration" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet24-sn02"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_app_vnet.name
  address_prefixes     = ["10.24.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true

  delegation {
    name = "${var.PREFIX}-${var.REGION}-${var.ENV}-func-del"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = "${var.PREFIX}-${var.REGION}-${var.ENV}-vnet24-sn03"
  resource_group_name  = var.RESOURCE_GROUP
  virtual_network_name = azurerm_virtual_network.sv_app_vnet.name
  address_prefixes     = ["10.24.3.0/24"]
#   service_endpoints    = ["Microsoft.Web"]
  enforce_private_link_endpoint_network_policies = true
}


# Virtual network peering for vnet21 and vnet23
resource "azurerm_virtual_network_peering" "vp_vnet21_vnet23" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet21-vnet23"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_bas_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vp_vnet23_vnet21" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet23-vnet21"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_bas_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Virtual network peering for vnet21 and vnet24
resource "azurerm_virtual_network_peering" "vp_vnet21_vnet24" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet21-vnet24"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_app_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vp_vnet24_vnet21" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet24-vnet21"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Virtual network peering for vnet23 and vnet24
resource "azurerm_virtual_network_peering" "vp_vnet23_vnet24" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet23-vnet24"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_bas_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_app_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vp_vnet24_vnet23" {
  name                      = "${var.PREFIX}-${var.REGION}-${var.ENV}-vp-vnet24-vnet23"
  resource_group_name       = var.RESOURCE_GROUP
  virtual_network_name      = azurerm_virtual_network.sv_app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.sv_bas_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}



# Add private dns zone vnet links
resource "azurerm_private_dns_zone_virtual_network_link" "kv_zone_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_kv_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.kv_zone.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_api_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_notebooks_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_blob_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_blob_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_blob.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa_zone_file_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_file_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.sa_zone_file.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_acr_zone_bas_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_app_acr_bas"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.app_acr_zone.name
  virtual_network_id    = azurerm_virtual_network.sv_bas_vnet.id
}