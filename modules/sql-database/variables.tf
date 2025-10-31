# SQL Database Module Variables

variable "prefix" {
  type        = string
  description = "Prefix for resource naming"
}

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
  description = "SQL Server administrator login"
  default     = "sqladmin"
}

variable "administrator_password" {
  type        = string
  description = "SQL Server administrator password (optional, random generated if not provided)"
  sensitive   = true
  default     = null
}

variable "database_name" {
  type        = string
  description = "SQL Database name"
}

variable "sku_name" {
  type        = string
  description = "SQL Database SKU"
  default     = "GP_Gen5_2"
}

variable "max_size_gb" {
  type        = number
  description = "Maximum size of the database in GB"
  default     = 32
}

variable "zone_redundant" {
  type        = bool
  description = "Enable zone redundancy"
  default     = false
}

variable "read_scale" {
  type        = bool
  description = "Enable read scale-out"
  default     = false
}

variable "geo_backup_enabled" {
  type        = bool
  description = "Enable geo-redundant backup"
  default     = true
}

variable "storage_account_type" {
  type        = string
  description = "Storage account type for backup"
  default     = "Geo"
  validation {
    condition     = contains(["Geo", "Local", "Zone"], var.storage_account_type)
    error_message = "Storage account type must be Geo, Local, or Zone."
  }
}

variable "short_term_retention_days" {
  type        = number
  description = "Short term retention in days (7-35)"
  default     = 7
  validation {
    condition     = var.short_term_retention_days >= 7 && var.short_term_retention_days <= 35
    error_message = "Short term retention days must be between 7 and 35."
  }
}

variable "weekly_backup_retention" {
  type        = string
  description = "Weekly backup retention (e.g., P1W)"
  default     = "P1W"
}

variable "monthly_backup_retention" {
  type        = string
  description = "Monthly backup retention (e.g., P1M)"
  default     = "P1M"
}

variable "yearly_backup_retention" {
  type        = string
  description = "Yearly backup retention (e.g., P1Y)"
  default     = null
}

variable "week_of_year" {
  type        = number
  description = "Week of year for yearly backup"
  default     = 1
}

variable "enable_tde" {
  type        = bool
  description = "Enable Transparent Data Encryption"
  default     = true
}

variable "tde_key_vault_key_id" {
  type        = string
  description = "Key Vault Key ID for TDE (optional, uses Microsoft-managed key if not provided)"
  default     = null
}

variable "azuread_admin_login" {
  type        = string
  description = "Azure AD administrator login name"
  default     = "sqladmin"
}

variable "azuread_admin_object_id" {
  type        = string
  description = "Azure AD administrator object ID"
  default     = null
}

variable "audit_storage_endpoint" {
  type        = string
  description = "Storage endpoint for SQL auditing"
  default     = null
}

variable "audit_storage_access_key" {
  type        = string
  description = "Storage access key for SQL auditing"
  sensitive   = true
  default     = null
}

variable "security_alert_emails" {
  type        = list(string)
  description = "Email addresses for security alerts"
  default     = []
}

variable "enable_vulnerability_assessment" {
  type        = bool
  description = "Enable SQL vulnerability assessment"
  default     = false
}

variable "vulnerability_assessment_storage_path" {
  type        = string
  description = "Storage container path for vulnerability assessment"
  default     = null
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint"
  default     = null
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Private DNS zone IDs for private endpoint"
  default     = []
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID to store SQL admin password"
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic settings"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
