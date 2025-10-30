# modules/sql-database/variables.tf

variable "prefix" { type = string }

variable "prefix" {variable "location" { type = string }

  type        = stringvariable "resource_group_name" { type = string }

  description = "Prefix for resource naming"variable "administrator_login" { type = string, default = "sqladmin" }

}variable "administrator_password" { type = string }


variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "administrator_login" {
  type        = string
  default     = "sqladmin"
  description = "SQL administrator login"
}

variable "administrator_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "SQL administrator password (if null, random password will be generated)"
}

variable "database_name" {
  type        = string
  default     = "appdb"
  description = "Database name"
}

variable "sku_name" {
  type        = string
  default     = "S0"
  description = "Database SKU name"
}

variable "max_size_gb" {
  type        = number
  default     = 50
  description = "Maximum database size in GB"
}

variable "zone_redundant" {
  type        = bool
  default     = false
  description = "Enable zone redundancy"
}

variable "geo_backup_enabled" {
  type        = bool
  default     = true
  description = "Enable geo-redundant backup"
}

variable "backup_storage_redundancy" {
  type        = string
  default     = "Local"
  description = "Backup storage redundancy (Local, Geo, Zone)"
}

variable "short_term_retention_days" {
  type        = number
  default     = 7
  description = "Short term retention in days"
}

variable "weekly_backup_retention" {
  type        = string
  default     = "P1W"
  description = "Weekly backup retention"
}

variable "monthly_backup_retention" {
  type        = string
  default     = "P1M"
  description = "Monthly backup retention"
}

variable "yearly_backup_retention" {
  type        = string
  default     = null
  description = "Yearly backup retention"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enable public network access"
}

variable "azuread_admin_login" {
  type        = string
  default     = "SQL Administrators"
  description = "Azure AD admin login name"
}

variable "azuread_admin_object_id" {
  type        = string
  default     = null
  description = "Azure AD admin object ID"
}

variable "key_vault_id" {
  type        = string
  default     = null
  description = "Key Vault ID for storing passwords"
}

variable "tde_key_vault_key_id" {
  type        = string
  default     = null
  description = "Key Vault Key ID for TDE"
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

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace ID"
}

variable "threat_detection_email_account_admins" {
  type        = bool
  default     = true
  description = "Email account admins on threat detection"
}

variable "threat_detection_email_addresses" {
  type        = list(string)
  default     = []
  description = "Email addresses for threat detection alerts"
}

variable "security_alert_email_account_admins" {
  type        = bool
  default     = true
  description = "Email account admins on security alerts"
}

variable "security_alert_email_addresses" {
  type        = list(string)
  default     = []
  description = "Email addresses for security alerts"
}

variable "enable_vulnerability_assessment" {
  type        = bool
  default     = false
  description = "Enable vulnerability assessment"
}

variable "storage_endpoint" {
  type        = string
  default     = null
  description = "Storage endpoint for vulnerability assessment"
}

variable "storage_access_key" {
  type        = string
  default     = null
  sensitive   = true
  description = "Storage access key for vulnerability assessment"
}

variable "vulnerability_email_subscription_admins" {
  type        = bool
  default     = true
  description = "Email subscription admins on vulnerability assessment"
}

variable "vulnerability_assessment_emails" {
  type        = list(string)
  default     = []
  description = "Email addresses for vulnerability assessment"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}
