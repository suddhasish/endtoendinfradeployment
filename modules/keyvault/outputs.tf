
output "keyvault_id" { 
  description = "Key Vault ID"
  value       = azurerm_key_vault.this.id 
}

output "keyvault_name" {
  description = "Key Vault Name"
  value       = azurerm_key_vault.this.name
}

output "keyvault_uri" { 
  description = "Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri 
}

output "cmk_key_id" {
  description = "CMK Key ID"
  value       = var.create_cmk_key ? azurerm_key_vault_key.cmk[0].id : null
}

output "cmk_key_version" {
  description = "CMK Key Version"
  value       = var.create_cmk_key ? azurerm_key_vault_key.cmk[0].version : null
}

output "private_endpoint_id" {
  description = "Private Endpoint ID"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.kv[0].id : null
}
