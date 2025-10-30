
variable "prefix" { 
  type        = string
  description = "Environment prefix"
  default     = "qa"
}

variable "location" { 
  type        = string
  description = "Azure region"
  default     = "eastus"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "azureapp"
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing"
  default     = "IT-QA"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for unique naming"
  default     = "dev01"
}

variable "aks_node_count" { 
  type        = number
  description = "Initial AKS node count"
  default     = 2
}

variable "aks_admin_group_object_ids" {
  type        = list(string)
  description = "Azure AD group object IDs for AKS admins"
  default     = []
}

variable "keyvault_admin_object_ids" {
  type        = list(string)
  description = "Azure AD object IDs for Key Vault admins"
  default     = []
}

variable "sql_administrator_login" {
  type        = string
  description = "SQL administrator login"
  default     = "sqladmin"
}

variable "sql_administrator_password" { 
  type        = string
  description = "SQL administrator password"
  sensitive   = true
}

variable "sql_database_name" {
  type        = string
  description = "SQL database name"
  default     = "appdb"
}
