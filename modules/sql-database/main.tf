# SQL Database Module - Clean Implementation

data "azurerm_client_config" "current" {}

# Random password for SQL Admin
resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.prefix}-sql"
  resource_group_name          = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_password != null ? var.administrator_password : random_password.sql_admin.result

  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  azuread_administrator {
    login_username = var.azuread_admin_login
    object_id      = var.azuread_admin_object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id

  sku_name             = var.sku_name
  max_size_gb          = var.max_size_gb
  zone_redundant       = var.zone_redundant
  read_scale           = var.read_scale
  geo_backup_enabled   = var.geo_backup_enabled
  storage_account_type = var.storage_account_type

  short_term_retention_policy {
    retention_days = var.short_term_retention_days
  }

  long_term_retention_policy {
    weekly_retention  = var.weekly_backup_retention
    monthly_retention = var.monthly_backup_retention
    yearly_retention  = var.yearly_backup_retention
    week_of_year      = var.week_of_year
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      license_type
    ]
  }
}

# Transparent Data Encryption
resource "azurerm_mssql_server_transparent_data_encryption" "main" {
  count = var.enable_tde ? 1 : 0

  server_id        = azurerm_mssql_server.main.id
  key_vault_key_id = var.tde_key_vault_key_id
}

# SQL Auditing
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id                               = azurerm_mssql_server.main.id
  storage_endpoint                        = var.audit_storage_endpoint
  storage_account_access_key              = var.audit_storage_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90
  log_monitoring_enabled                  = true
}

# Security Alert Policy
resource "azurerm_mssql_server_security_alert_policy" "main" {
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.main.name
  state               = "Enabled"

  email_account_admins = true
  email_addresses      = var.security_alert_emails
  retention_days       = 30
}

# Vulnerability Assessment
resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  count = var.enable_vulnerability_assessment ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id
  storage_container_path          = var.vulnerability_assessment_storage_path
  storage_account_access_key      = var.audit_storage_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.security_alert_emails
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "sql" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_mssql_server.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_mssql_server.main.name}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# Store SQL Admin Password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  count = var.key_vault_id != null ? 1 : 0

  name         = "sql-admin-password-${var.prefix}"
  value        = var.administrator_password != null ? var.administrator_password : random_password.sql_admin.result
  key_vault_id = var.key_vault_id

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_mssql_server.main.name}"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_log {
    category = "DevOpsOperationsAudit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_mssql_database.main.name}"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_log {
    category = "DatabaseWaitStatistics"
  }

  enabled_log {
    category = "Timeouts"
  }

  enabled_log {
    category = "Blocks"
  }

  enabled_log {
    category = "Deadlocks"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
