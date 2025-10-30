# modules/monitoring/variables.tf

variable "prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "sku" {
  type        = string
  description = "SKU for Log Analytics Workspace"
  default     = "PerGB2018"
}

variable "retention_in_days" {
  type        = number
  description = "Log retention in days"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "nsg_ids" {
  type        = map(string)
  description = "Map of NSG IDs for diagnostic settings"
  default     = {}
}
