provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  default = "Australia East"
}

variable "resource_group_name" {
  default = "revhire-resources"
}

variable "vnet_name" {
  default = "revhire-vnet"
}

variable "aks_node_count" {
  default = 1
}

variable "aks_node_vm_size" {
  default = "Standard_B2s"
}

variable "acr_name" {
  default = "revhireacr"
}

variable "sql_server_name" {
  default = "revhire-sql-server"
}

variable "sql_admin_username" {
  default = "sqladmin"
}

variable "sql_admin_password" {
  default = "Admin123@"
}

variable "mysql_server_name" {
  default = "revhire-mysql-server"
}

variable "mysql_admin_username" {
  default = "mysqladmin"
}

variable "mysql_admin_password" {
  default = "MySQLAdmin123@"
}

# Resource Group
resource "azurerm_resource_group" "revhire" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "revhire-vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.revhire.location
  resource_group_name = azurerm_resource_group.revhire.name
}

# Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "revhire-aks" {
  name                = "revhire-aks"
  location            = azurerm_resource_group.revhire.location
  resource_group_name = azurerm_resource_group.revhire.name
  dns_prefix          = "revhireaks"

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "revhire-acr" {
  name                     = var.acr_name
  resource_group_name      = azurerm_resource_group.revhire.name
  location                 = azurerm_resource_group.revhire.location
  sku                      = "Basic"
  admin_enabled            = true
}

# Azure SQL Server
resource "azurerm_sql_server" "revhire-sql-server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.revhire.name
  location                     = azurerm_resource_group.revhire.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  tags = {
    environment = "development"
  }
}

# Azure SQL Database
resource "azurerm_sql_database" "revhire-db" {
  name                            = "revhire-db"
  resource_group_name             = azurerm_resource_group.revhire.name
  location                        = azurerm_resource_group.revhire.location
  server_name                     = azurerm_sql_server.revhire-sql-server.name
  edition                         = "Basic"
  requested_service_objective_name = "Basic"
}

# Azure MySQL Server
resource "azurerm_mysql_server" "revhire-mysql-server" {
  name                             = var.mysql_server_name
  location                         = azurerm_resource_group.revhire.location
  resource_group_name              = azurerm_resource_group.revhire.name

  administrator_login              = var.mysql_admin_username
  administrator_login_password     = var.mysql_admin_password

  sku_name                         = "B_Gen5_1"
  storage_mb                       = 5120
  version                          = "5.7"

  backup_retention_days            = 7
  geo_redundant_backup_enabled     = false
  ssl_enforcement_enabled          = true

  tags = {
    environment = "production"
  }
}

# Azure MySQL Database
resource "azurerm_mysql_database" "revhire-mysql-db" {
  name                = "revhire-mysql-db"
  resource_group_name = azurerm_resource_group.revhire.name
  server_name         = azurerm_mysql_server.revhire-mysql-server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.revhire.name
  sensitive = true
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.revhire-vnet.name
  sensitive = true
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.revhire-aks.name
  sensitive = true
}

output "aks_cluster_kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.revhire-aks.kube_config_raw
  sensitive   = true
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.revhire-acr.name
  sensitive = true
}

output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.revhire-acr.login_server
  sensitive = true
}

output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_sql_server.revhire-sql-server.name
  sensitive = true
}

output "sql_database_name" {
  description = "The name of the SQL Database"
  value       = azurerm_sql_database.revhire-db.name
  sensitive = true
}

output "mysql_server_name" {
  description = "The name of the MySQL Server"
  value       = azurerm_mysql_server.revhire-mysql-server.name
  sensitive = true
}

output "mysql_database_name" {
  description = "The name of the MySQL Database"
  value       = azurerm_mysql_database.revhire-mysql-db.name
  sensitive = true
}
