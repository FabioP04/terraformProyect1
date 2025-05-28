
# Data source to access the properties of an existing Azure Public IP Address
data "azurerm_public_ip" "web_cluster_public_ip_data" {
  name                = azurerm_public_ip.web_cluster_public_ip.name
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
}

# Output variable: Public IP address
output "public_ip" {
  value = data.azurerm_public_ip.web_cluster_public_ip_data.ip_address
}
