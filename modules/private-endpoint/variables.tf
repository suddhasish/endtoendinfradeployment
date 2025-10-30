
variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "private_service_connection" { type = map(any) }
