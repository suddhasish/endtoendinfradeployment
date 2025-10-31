
output "hub_rg_name" { value = azurerm_resource_group.hub.name }
output "hub_vnet_id" { value = azurerm_virtual_network.hub.id }
output "appgw_subnet_id" { value = azurerm_subnet.appgw.id }
output "pe_subnet_id" { value = azurerm_subnet.pe.id }
output "bastion_subnet_id" { value = azurerm_subnet.bastion.id }
output "firewall_subnet_id" { value = azurerm_subnet.firewall.id }
output "spoke_rg" { value = azurerm_resource_group.spoke_rg }
output "spoke_aks_subnet_ids" { value = { for k, s in azurerm_subnet.aks : k => s.id } }
output "spoke_db_subnet_ids" { value = { for k, s in azurerm_subnet.db : k => s.id } }
output "private_dns_zone_keyvault_id" { value = azurerm_private_dns_zone.keyvault.id }
output "private_dns_zone_storage_blob_id" { value = azurerm_private_dns_zone.storage_blob.id }
output "private_dns_zone_storage_file_id" { value = azurerm_private_dns_zone.storage_file.id }
output "private_dns_zone_sql_id" { value = azurerm_private_dns_zone.sql.id }
output "private_dns_zone_aks_id" { value = azurerm_private_dns_zone.aks.id }
