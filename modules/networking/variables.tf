
variable "prefix" { 
  type        = string 
  description = "Prefix for resource naming"
}

variable "location" { 
  type        = string
  default     = "eastus"
  description = "Azure region for resources"
}

variable "hub_address_space" { 
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for hub VNet"
}

variable "spokes" {
  type = map(object({ 
    address_space = list(string) 
  }))
  description = "Map of spoke name to address space"
  default     = { 
    workload = { 
      address_space = ["10.1.0.0/16"] 
    } 
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
