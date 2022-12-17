# Azure Machine Learning Workspace with Private Link

resource "azurerm_machine_learning_workspace" "sv_ws" {
  name                    = "${var.PREFIX}-${var.REGION}-aml-wrksp-${var.ENV}"
  friendly_name           = var.WORKSPACE_DISPLAY_NAME
  location                = var.LOCATION
  resource_group_name     = var.RESOURCE_GROUP
  application_insights_id = azurerm_application_insights.sv_ai.id
  key_vault_id            = azurerm_key_vault.sv_kv.id
  storage_account_id      = azurerm_storage_account.sv_sa.id
  container_registry_id   = azurerm_container_registry.sv_acr_aml.id
  

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false
  v1_legacy_mode  = true
}

resource "azurerm_machine_learning_compute_instance" "sv_ws_comp_inst" {
  name                          = "ci-${random_string.postfix.result}-test"
  location                      = var.LOCATION
  machine_learning_workspace_id = azurerm_machine_learning_workspace.sv_ws.id
  virtual_machine_size          = "Standard_DS3_v2"
  authorization_type            = "personal"
  
  subnet_resource_id = azurerm_subnet.compute_subnet.id
  description        = "smart video"
  tags = {
    foo = "smart video"
  }
}

resource "azurerm_machine_learning_compute_cluster" "sv_ws_cluster" {
  name                          = var.AML_COMPUTE_TARGET
  location                      = var.LOCATION
  vm_priority                   = "LowPriority"
  vm_size                       = var.AML_COMPUTE_TARGET_VM_SIZE
  machine_learning_workspace_id = azurerm_machine_learning_workspace.sv_ws.id
  subnet_resource_id            = azurerm_subnet.compute_subnet.id
  ssh_public_access_enabled     = false
  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 3
    scale_down_nodes_after_idle_duration = "PT30S" # 30 seconds
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "smart video"
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "ws_zone_api" {
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.RESOURCE_GROUP
}

resource "azurerm_private_dns_zone" "ws_zone_notebooks" {
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.RESOURCE_GROUP
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_api_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_api"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_api.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ws_zone_notebooks_link" {
  name                  = "${var.PREFIX}_${var.REGION}_link_notebooks"
  resource_group_name   = var.RESOURCE_GROUP
  private_dns_zone_name = azurerm_private_dns_zone.ws_zone_notebooks.name
  virtual_network_id    = azurerm_virtual_network.sv_vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "ws_pe" {
  name                = "${var.PREFIX}-${var.REGION}-aml-${var.ENV}-pe"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  subnet_id           = azurerm_subnet.sv_subnet.id

  private_service_connection {
    name                           = "${var.PREFIX}-${var.REGION}-aml-${var.ENV}-psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.sv_ws.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-ws"
    private_dns_zone_ids = [azurerm_private_dns_zone.ws_zone_api.id, azurerm_private_dns_zone.ws_zone_notebooks.id]
  }

  # Add Private Link after we configured the workspace
  depends_on = [azurerm_machine_learning_compute_instance.sv_ws_comp_inst, azurerm_machine_learning_compute_cluster.sv_ws_cluster]
}
