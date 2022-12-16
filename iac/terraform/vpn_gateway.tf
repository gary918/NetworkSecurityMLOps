# Azure VPN gateway 
resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "${var.PREFIX}-${var.REGION}-pip-vpngateway-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  allocation_method = "Dynamic"
}
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "${var.PREFIX}-${var.REGION}-vpn-gateway-${var.ENV}"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  type     = "Vpn"
  vpn_type = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "Standard" #VPN gateway with basic tier does not support redius authendication
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     =  azurerm_subnet.vpn_gateway_subnet.id
  }
}