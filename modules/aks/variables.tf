
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
  description = "Subnet ID for AKS nodes"
}

variable "node_count" { 
  type        = number
  default     = 2 
  description = "Initial node count for system node pool"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = "VM size for system node pool"
}

variable "max_pods" {
  type        = number
  default     = 110
  description = "Maximum pods per node"
}

variable "enable_auto_scaling" {
  type        = bool
  default     = true
  description = "Enable autoscaling for node pools"
}

variable "min_count" {
  type        = number
  default     = 2
  description = "Minimum node count for autoscaling"
}

variable "max_count" {
  type        = number
  default     = 10
  description = "Maximum node count for autoscaling"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Availability zones for node pools"
}

variable "private_cluster_enabled" {
  type        = bool
  default     = true
  description = "Enable private AKS cluster"
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "Private DNS Zone ID for private cluster"
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "AKS SKU tier (Free or Standard)"
}

variable "local_account_disabled" {
  type        = bool
  default     = true
  description = "Disable local accounts (use AAD only)"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID"
}

variable "admin_group_object_ids" {
  type        = list(string)
  default     = []
  description = "AAD group object IDs for AKS admins"
}

variable "enable_agic" {
  type        = bool
  default     = true
  description = "Enable Application Gateway Ingress Controller"
}

variable "application_gateway_id" {
  type        = string
  default     = null
  description = "Application Gateway ID for AGIC"
}

variable "appgw_resource_group_name" {
  type        = string
  default     = ""
  description = "Application Gateway resource group name"
}

variable "dns_service_ip" {
  type        = string
  default     = "10.2.0.10"
  description = "DNS service IP"
}

variable "service_cidr" {
  type        = string
  default     = "10.2.0.0/16"
  description = "Service CIDR"
}

variable "outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "Outbound type (loadBalancer or userDefinedRouting)"
}

variable "workload_identity_enabled" {
  type        = bool
  default     = true
  description = "Enable workload identity"
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = true
  description = "Enable OIDC issuer"
}

variable "enable_user_node_pool" {
  type        = bool
  default     = true
  description = "Enable additional user node pool"
}

variable "user_node_pool_vm_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = "VM size for user node pool"
}

variable "user_node_pool_count" {
  type        = number
  default     = 3
  description = "Node count for user node pool"
}

variable "user_node_pool_min_count" {
  type        = number
  default     = 3
  description = "Minimum node count for user node pool autoscaling"
}

variable "user_node_pool_max_count" {
  type        = number
  default     = 20
  description = "Maximum node count for user node pool autoscaling"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}
