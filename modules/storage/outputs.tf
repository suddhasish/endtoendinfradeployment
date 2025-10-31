
output "storage_account_id" {
  description = "Storage Account ID"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Storage Account Name"
  value       = azurerm_storage_account.this.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary Blob Endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "storage_account_principal_id" {
  description = "Storage Account System Assigned Identity Principal ID"
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "tfstate_container" {
  description = "Tfstate Container Name"
  value       = azurerm_storage_container.tfstate.name
}

output "private_endpoint_blob_id" {
  description = "Blob Private Endpoint ID"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.blob[0].id : null
}

output "private_endpoint_file_id" {
  description = "File Private Endpoint ID"
  value       = var.private_endpoint_subnet_id != null && var.enable_file_share ? azurerm_private_endpoint.file[0].id : null
}
