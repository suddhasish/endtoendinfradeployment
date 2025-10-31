
variable "name" {
  type        = string
  description = "Storage Account name (must be globally unique)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "Storage account tier"
}

variable "account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Storage account replication type"
}

variable "account_kind" {
  type        = string
  default     = "StorageV2"
  description = "Storage account kind"
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = "Enable shared access key"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enable public network access"
}

variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "Enable hierarchical namespace (Data Lake Gen2)"
}

variable "blob_soft_delete_retention_days" {
  type        = number
  default     = 30
  description = "Blob soft delete retention in days"
}

variable "container_soft_delete_retention_days" {
  type        = number
  default     = 30
  description = "Container soft delete retention in days"
}

variable "network_default_action" {
  type        = string
  default     = "Deny"
  description = "Default network action"
}

variable "network_ip_rules" {
  type        = list(string)
  default     = []
  description = "IP rules for network ACLs"
}

variable "network_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Subnet IDs for network ACLs"
}

variable "cmk_key_vault_key_id" {
  type        = string
  default     = null
  description = "Key Vault Key ID for CMK encryption"
}

variable "cmk_key_vault_id" {
  type        = string
  default     = null
  description = "Key Vault ID for CMK encryption"
}

variable "cmk_key_name" {
  type        = string
  default     = null
  description = "Key Vault Key name for CMK encryption"
}

variable "additional_containers" {
  type        = list(string)
  default     = []
  description = "Additional storage containers to create"
}

variable "enable_lifecycle_policy" {
  type        = bool
  default     = true
  description = "Enable lifecycle management policy"
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for private endpoint"
}

variable "private_dns_zone_blob_id" {
  type        = string
  default     = null
  description = "Private DNS zone ID for blob"
}

variable "private_dns_zone_file_id" {
  type        = string
  default     = null
  description = "Private DNS zone ID for file"
}

variable "enable_file_share" {
  type        = bool
  default     = false
  description = "Enable file share private endpoint"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace ID"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}

# Deprecated - keeping for backward compatibility
variable "sku" {
  type        = string
  default     = "Standard_LRS"
  description = "Deprecated - use account_tier and account_replication_type"
}
