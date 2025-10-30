
output "appgw_id" { 
  description = "Application Gateway ID"
  value       = azurerm_application_gateway.this.id 
}

output "appgw_name" {
  description = "Application Gateway Name"
  value       = azurerm_application_gateway.this.name
}

output "appgw_public_ip" { 
  description = "Application Gateway Public IP"
  value       = azurerm_public_ip.pip.ip_address 
}

output "appgw_public_ip_fqdn" {
  description = "Application Gateway Public IP FQDN"
  value       = azurerm_public_ip.pip.fqdn
}

output "appgw_identity_principal_id" {
  description = "Application Gateway Managed Identity Principal ID"
  value       = azurerm_user_assigned_identity.appgw.principal_id
}

output "waf_policy_id" {
  description = "WAF Policy ID"
  value       = azurerm_web_application_firewall_policy.waf.id
}
