# SQL Database Module Outputs

output "sql_server_id" {
  description = "SQL Server ID"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_name" {
  description = "SQL Server Name"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "SQL Database ID"
  value       = azurerm_mssql_database.main.id
}

output "sql_database_name" {
  description = "SQL Database Name"
  value       = azurerm_mssql_database.main.name
}

output "sql_server_principal_id" {
  description = "SQL Server System Assigned Identity Principal ID"
  value       = azurerm_mssql_server.main.identity[0].principal_id
}

output "private_endpoint_id" {
  description = "Private Endpoint ID"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.sql[0].id : null
}

output "sql_admin_password_secret_id" {
  description = "Key Vault Secret ID for SQL Admin Password"
  value       = var.key_vault_id != null ? azurerm_key_vault_secret.sql_admin_password[0].id : null
  sensitive   = true
}
