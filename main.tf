terraform {
  required_version = ">= 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.1.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "web_cluster_rg" {
  name     = "my-terraform-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "web_cluster_vnet" {
  name                = "my-terraform-vnet"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_subnet" "web_cluster_subnet" {
  name                 = "my-terraform-subnet"
  resource_group_name  = azurerm_resource_group.web_cluster_rg.name
  virtual_network_name = azurerm_virtual_network.web_cluster_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "monitoring_nsg" {
  name                = "monitoring-nsg"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name

  security_rule {
    name                       = "Allow-Prometheus"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Grafana"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_public_ip" "web_cluster_public_ip" {
  name                = "my-terraform-public-ip"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
  allocation_method   = "Static"

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_lb" "web_cluster_lb" {
  name                = "my-terraform-lb"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name

  frontend_ip_configuration {
    name                 = "my-terraform-lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_cluster_public_ip.id
  }

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_lb_backend_address_pool" "web_cluster_lb_backend_pool" {
  name            = "my-terraform-lb-backend-pool"
  loadbalancer_id = azurerm_lb.web_cluster_lb.id
}

resource "azurerm_lb_probe" "web_cluster_lb_probe" {
  name            = "my-terraform-lb-probe"
  loadbalancer_id = azurerm_lb.web_cluster_lb.id
  port            = var.server_port
}

resource "azurerm_lb_rule" "web_cluster_lb_rule" {
  name                           = "my-terraform-lb-rule"
  loadbalancer_id                = azurerm_lb.web_cluster_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = var.server_port
  frontend_ip_configuration_name = "my-terraform-lb-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_cluster_lb_backend_pool.id]
  probe_id                      = azurerm_lb_probe.web_cluster_lb_probe.id
}

resource "azurerm_linux_virtual_machine_scale_set" "web_cluster_vmss" {
  name                             = "my-terraform-vm-scale-set"
  location                         = azurerm_resource_group.web_cluster_rg.location
  resource_group_name              = azurerm_resource_group.web_cluster_rg.name
  sku                              = "Standard_DS1_v2"
  instances                        = 2
  admin_username                   = "azureuser"
  admin_password                   = "Password1234!"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "my-terraform-vm-ss-nic"
    primary = true

    ip_configuration {
      name                                    = "my-terraform-vm-ss-nic-ip"
      primary                                 = true
      subnet_id                               = azurerm_subnet.web_cluster_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_cluster_lb_backend_pool.id]
    }
  }

  extension {
    name                 = "hostname"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"

    settings = <<SETTINGS
{
  "commandToExecute": "echo 'Hello, World from my web cluster' > index.html ; nohup busybox httpd -f -p ${var.server_port} &"
}
SETTINGS
  }

  tags = {
    environment = "my-terraform-env"
  }
}

# Máquina de monitorización

resource "azurerm_public_ip" "monitoring_public_ip" {
  name                = "monitoring-public-ip"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
  allocation_method   = "Static"

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_network_interface" "monitoring_nic" {
  name                = "monitoring-nic"
  location            = azurerm_resource_group.web_cluster_rg.location
  resource_group_name = azurerm_resource_group.web_cluster_rg.name
  network_security_group_id = azurerm_network_security_group.monitoring_nsg.id

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web_cluster_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.monitoring_public_ip.id
  }

  tags = {
    environment = "my-terraform-env"
  }
}

resource "azurerm_linux_virtual_machine" "monitoring_vm" {
  name                            = "monitoring-vm"
  location                        = azurerm_resource_group.web_cluster_rg.location
  resource_group_name             = azurerm_resource_group.web_cluster_rg.name
  size                            = "Standard_DS1_v2"
  admin_username                 = "azureuser"
  admin_password                 = "Password1234!"
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.monitoring_nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = "my-terraform-env"
  }

  # Instala Prometheus y Grafana usando VM Extension
}

resource "azurerm_virtual_machine_extension" "monitoring_vm_extension" {
  name                 = "install-prometheus-grafana"
  virtual_machine_id   = azurerm_linux_virtual_machine.monitoring_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
{
  "commandToExecute": "sudo apt-get update && sudo apt-get install -y wget apt-transport-https software-properties-common && \
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add - && \
echo 'deb https://packages.grafana.com/oss/deb stable main' | sudo tee -a /etc/apt/sources.list.d/grafana.list && \
sudo apt-get update && sudo apt-get install -y grafana prometheus && \
sudo systemctl enable prometheus && sudo systemctl start prometheus && \
sudo systemctl enable grafana-server && sudo systemctl start grafana-server"
}
SETTINGS
}
