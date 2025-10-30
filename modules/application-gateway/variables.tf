
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

variable "subnet_id" { 
  type        = string
  description = "Subnet ID for Application Gateway"
}

variable "sku_name" {
  type        = string
  default     = "WAF_v2"
  description = "Application Gateway SKU name"
}

variable "sku_tier" {
  type        = string
  default     = "WAF_v2"
  description = "Application Gateway SKU tier"
}

variable "capacity" {
  type        = number
  default     = null
  description = "Fixed capacity (if not using autoscale)"
}

variable "autoscale_min_capacity" {
  type        = number
  default     = 2
  description = "Minimum autoscale capacity"
}

variable "autoscale_max_capacity" {
  type        = number
  default     = 10
  description = "Maximum autoscale capacity"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Availability zones"
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

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace ID for diagnostic settings"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}
