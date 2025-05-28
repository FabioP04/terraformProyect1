data "azurerm_public_ip" "web_cluster_public_ip_data" {
  name                = azurerm_public_ip.web_cluster_public_ip.name
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
}

output "public_ip" {
  value = data.azurerm_public_ip.web_cluster_public_ip_data.ip_address
}

data "azurerm_public_ip" "monitoring_public_ip_data" {
  name                = azurerm_public_ip.monitoring_public_ip.name
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
}

output "monitoring_public_ip" {
  value = data.azurerm_public_ip.monitoring_public_ip_data.ip_address
}
