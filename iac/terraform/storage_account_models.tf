# Public Storage Account for storing registered models

resource "azurerm_storage_account" "model" {
  name                     = "${var.PREFIX}${var.REGION}strmodel${var.ENV}"
  location                 = var.LOCATION
  resource_group_name      = var.RESOURCE_GROUP
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_role_assignment" "sa_mdl_blob_ctr" {
  scope                = azurerm_storage_account.model.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.sv_ws.identity[0].principal_id
}

resource "azurerm_role_assignment" "sa_mdl_ctr" {
  scope                = azurerm_storage_account.model.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_machine_learning_workspace.sv_ws.identity[0].principal_id
}

# Add a default container for storing models
resource "azurerm_storage_container" "model_con" {
  name                  = "amlmodels"
  storage_account_name  = azurerm_storage_account.model.name
  container_access_type = "private"
}

