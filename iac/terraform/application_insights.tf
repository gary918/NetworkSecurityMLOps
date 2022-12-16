# Application Insights for Azure Machine Learning (no Private Link/VNET integration)

resource "azurerm_application_insights" "sv_ai" {
  name                = "${var.PREFIX}-${var.REGION}-api-log-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  application_type    = "web"
}