
variable "name" { 
  type        = string
  description = "Key Vault name"
}

variable "location" { 
  type        = string
  description = "Azure region"
}

variable "resource_group_name" { 
  type        = string
  description = "Resource group name"
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "SKU name (standard or premium)"
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Enable purge protection"
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 90
  description = "Soft delete retention in days"
}

variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Enable for VM deployment"
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = true
  description = "Enable for disk encryption"
}

variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = "Enable for ARM template deployment"
}

variable "enable_rbac_authorization" {
  type        = bool
  default     = true
  description = "Use RBAC instead of access policies"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enable public network access"
}

variable "network_acls_default_action" {
  type        = string
  default     = "Deny"
  description = "Default action for network ACLs"
}

variable "network_acls_ip_rules" {
  type        = list(string)
  default     = []
  description = "IP rules for network ACLs"
}

variable "network_acls_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Subnet IDs for network ACLs"
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for private endpoint"
}

variable "private_dns_zone_ids" {
  type        = list(string)
  default     = []
  description = "Private DNS zone IDs"
}

variable "admin_object_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs for Key Vault Administrators (RBAC)"
}

variable "secrets_officer_object_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs for Key Vault Secrets Officers (RBAC)"
}

variable "secrets_user_object_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs for Key Vault Secrets Users (RBAC)"
}

variable "create_cmk_key" {
  type        = bool
  default     = false
  description = "Create a CMK key for encryption"
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
