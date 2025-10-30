
output "aks_cluster_name" { value = azurerm_kubernetes_cluster.aks.name }
output "aks_uai_id" { value = azurerm_user_assigned_identity.uai.id }
