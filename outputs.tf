data "azurerm_public_ip" "web_cluster_public_ip_data" {
  name                = azurerm_public_ip.web_cluster_public_ip.name
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
}

output "vmss_public_ip" {
  description = "Public IP address of the load balancer for the VMSS"
  value       = data.azurerm_public_ip.web_cluster_public_ip_data.ip_address
}

output "monitoring_vm_public_ip" {
  description = "Public IP address of the monitoring VM"
  value       = azurerm_public_ip.monitoring_public_ip.ip_address
}
