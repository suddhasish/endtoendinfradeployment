
variable "prefix" { 
  type        = string
  description = "Prefix for resource naming"
}

variable "resource_group_name" { 
  type        = string
  description = "Resource group name"
}

variable "backend_hostname" { 
  type        = string
  description = "Backend hostname/IP"
}

variable "sku_name" {
  type        = string
  default     = "Standard_AzureFrontDoor"
  description = "Front Door SKU (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  }
}

variable "waf_mode" {
  type        = string
  default     = "Prevention"
  description = "WAF mode (Detection or Prevention)"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be Detection or Prevention"
  }
}

variable "waf_redirect_url" {
  type        = string
  default     = null
  description = "WAF redirect URL"
}

variable "health_probe_protocol" {
  type        = string
  default     = "Https"
  description = "Health probe protocol"
}

variable "health_probe_path" {
  type        = string
  default     = "/healthz"
  description = "Health probe path"
}

variable "rule_set_ids" {
  type        = list(string)
  default     = []
  description = "Front Door rule set IDs"
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
