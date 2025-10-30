# Networking Outputs
output "hub_rg_name" {
  description = "Hub resource group name"
  value       = module.network.hub_rg_name
}

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = module.network.hub_vnet_id
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

# AKS Outputs
output "aks_cluster_name" {
  description = "AKS Cluster Name"
  value       = module.aks.aks_cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS Cluster FQDN"
  value       = module.aks.aks_fqdn
}

output "aks_node_resource_group" {
  description = "AKS Node Resource Group"
  value       = module.aks.aks_node_resource_group
}

# Application Gateway Outputs
output "appgw_public_ip" {
  description = "Application Gateway Public IP"
  value       = module.appgw.appgw_public_ip
}

output "appgw_id" {
  description = "Application Gateway ID"
  value       = module.appgw.appgw_id
}

# Key Vault Outputs
output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.keyvault_uri
}

output "keyvault_name" {
  description = "Key Vault Name"
  value       = module.keyvault.keyvault_name
}

# SQL Outputs
output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = module.sql.sql_server_fqdn
}

output "sql_database_name" {
  description = "SQL Database Name"
  value       = module.sql.sql_database_name
}

# Storage Outputs
output "storage_account_name" {
  description = "Storage Account Name"
  value       = module.storage.storage_account_name
}

# Front Door Outputs
output "frontdoor_endpoint_hostname" {
  description = "Front Door Endpoint Hostname"
  value       = module.frontdoor.frontdoor_endpoint_hostname
}
