
# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "uai" {
  name                = "${var.prefix}-aks-uai"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# User Assigned Identity for AGIC
resource "azurerm_user_assigned_identity" "agic" {
  name                = "${var.prefix}-agic-uai"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Role Assignment for AGIC to manage Application Gateway
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  count                = var.enable_agic ? 1 : 0
  scope                = var.application_gateway_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

resource "azurerm_role_assignment" "agic_appgw_rg_reader" {
  count                = var.enable_agic ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.appgw_resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

data "azurerm_client_config" "current" {}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = "${var.prefix}-aks"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = "${var.prefix}-aks"
  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = var.private_cluster_enabled ? var.private_dns_zone_id : null
  automatic_channel_upgrade         = "stable"
  sku_tier                          = var.sku_tier
  node_resource_group               = "${var.resource_group_name}-aks-nodes"
  azure_policy_enabled              = true
  role_based_access_control_enabled = true
  local_account_disabled            = var.local_account_disabled

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = var.subnet_id
    max_pods            = var.max_pods
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
    zones               = var.availability_zones

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.prefix
      "nodepoolos"    = "linux"
    }

    tags = var.tags
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  dynamic "ingress_application_gateway" {
    for_each = var.enable_agic ? [1] : []
    content {
      gateway_id = var.application_gateway_id
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.oidc_issuer_enabled

  tags = merge(
    var.tags,
    {
      environment = var.prefix
    }
  )

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  depends_on = [
    azurerm_role_assignment.agic_appgw_contributor,
    azurerm_role_assignment.agic_appgw_rg_reader
  ]
}

# Additional User Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.enable_user_node_pool ? 1 : 0
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_count
  vnet_subnet_id        = var.subnet_id
  max_pods              = var.max_pods
  os_disk_size_gb       = 128
  os_disk_type          = "Managed"
  enable_auto_scaling   = var.enable_auto_scaling
  min_count             = var.enable_auto_scaling ? var.user_node_pool_min_count : null
  max_count             = var.enable_auto_scaling ? var.user_node_pool_max_count : null
  zones                 = var.availability_zones
  mode                  = "User"

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.prefix
    "nodepoolos"    = "linux"
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${azurerm_kubernetes_cluster.aks.name}"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
