
output "frontdoor_id" {
  description = "Front Door Profile ID"
  value       = azurerm_cdn_frontdoor_profile.fd.id
}

output "frontdoor_name" {
  description = "Front Door Profile Name"
  value       = azurerm_cdn_frontdoor_profile.fd.name
}

output "frontdoor_endpoint_hostname" {
  description = "Front Door Endpoint Hostname"
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

output "frontdoor_endpoint_id" {
  description = "Front Door Endpoint ID"
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.id
}

output "waf_policy_id" {
  description = "WAF Policy ID"
  value       = azurerm_cdn_frontdoor_firewall_policy.waf.id
}
