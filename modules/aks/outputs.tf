
output "aks_cluster_name" { value = azurerm_kubernetes_cluster.aks.name }
output "aks_cluster_id" { value = azurerm_kubernetes_cluster.aks.id }
output "aks_uai_id" { value = azurerm_user_assigned_identity.uai.id }
output "aks_kubelet_identity" { value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id }
output "aks_fqdn" { value = azurerm_kubernetes_cluster.aks.fqdn }
output "aks_node_resource_group" { value = azurerm_kubernetes_cluster.aks.node_resource_group }
output "agic_identity_id" { value = azurerm_user_assigned_identity.agic.id }
output "agic_client_id" { value = azurerm_user_assigned_identity.agic.client_id }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.aks.oidc_issuer_url }
