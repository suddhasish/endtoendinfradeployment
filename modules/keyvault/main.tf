
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "this" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  public_network_access_enabled   = var.public_network_access_enabled

  network_acls {
    default_action             = var.network_acls_default_action
    bypass                     = "AzureServices"
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.network_acls_subnet_ids
  }

  tags = merge(
    var.tags,
    {
      environment = var.resource_group_name
    }
  )
}

# Private Endpoint
resource "azurerm_private_endpoint" "kv" {
  count               = length([var.private_endpoint_subnet_id]) > 0 ? 1 : 0
  name                = "pe-${azurerm_key_vault.this.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_key_vault.this.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-kv"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# RBAC Role Assignments
resource "azurerm_role_assignment" "kv_admin" {
  for_each             = var.enable_rbac_authorization ? toset(var.admin_object_ids) : toset([])
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each             = var.enable_rbac_authorization ? toset(var.secrets_officer_object_ids) : toset([])
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = var.enable_rbac_authorization ? toset(var.secrets_user_object_ids) : toset([])
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# Access Policies (for non-RBAC mode)
resource "azurerm_key_vault_access_policy" "current_user" {
  count        = var.enable_rbac_authorization ? 0 : 1
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]

  key_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Purge",
    "Encrypt", "Decrypt", "Sign", "Verify", "WrapKey", "UnwrapKey"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Purge",
    "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers"
  ]
}

# CMK Key for encryption
resource "azurerm_key_vault_key" "cmk" {
  count        = var.create_cmk_key ? 1 : 0
  name         = "${var.name}-cmk"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_role_assignment.kv_admin
  ]
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = length([var.log_analytics_workspace_id]) > 0 ? 1 : 0
  name                       = "diag-${azurerm_key_vault.this.name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
