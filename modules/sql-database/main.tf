# modules/sql-database/main.tf# terraform/modules/sql-database/main.tf



data "azurerm_client_config" "current" {}terraform {

  required_version = ">= 1.6.0"

# Random password for SQL Admin  required_providers {

resource "random_password" "sql_admin" {    azurerm = {

  length           = 24      source  = "hashicorp/azurerm"

  special          = true      version = "~> 3.85"

  override_special = "!#$%&*()-_=+[]{}:?"    }

  min_lower        = 1    random = {

  min_upper        = 1      source  = "hashicorp/random"

  min_numeric      = 1      version = "~> 3.6"

  min_special      = 1    }

}  }

}

# SQL Server

resource "azurerm_mssql_server" "main" {data "azurerm_client_config" "current" {}

  name                          = "${var.prefix}-sql"

  resource_group_name           = var.resource_group_namelocals {

  location                      = var.location  common_tags = merge(

  version                       = "12.0"    var.tags,

  administrator_login           = var.administrator_login    {

  administrator_login_password  = var.administrator_password != null ? var.administrator_password : random_password.sql_admin.result      ManagedBy   = "Terraform"

  minimum_tls_version           = "1.2"      Module      = "SQL"

  public_network_access_enabled = var.public_network_access_enabled      Environment = var.environment

    }

  azuread_administrator {  )

    login_username = var.azuread_admin_login}

    object_id      = var.azuread_admin_object_id != null ? var.azuread_admin_object_id : data.azurerm_client_config.current.object_id

  }# Random password for SQL Admin

resource "random_password" "sql_admin" {

  identity {  length           = 24

    type = "SystemAssigned"  special          = true

  }  override_special = "!#$%&*()-_=+[]{}<>:?"

  min_lower        = 1

  tags = merge(  min_upper        = 1

    var.tags,  min_numeric      = 1

    {  min_special      = 1

      environment = var.prefix}

    }

  )# SQL Server

resource "azurerm_mssql_server" "main" {

  lifecycle {  name                          = "sql-${var.project_name}-${var.environment}-${var.location_short}"

    ignore_changes = [  resource_group_name           = var.resource_group_name

      administrator_login_password  location                      = var.location

    ]  version                       = "12.0"

  }  administrator_login           = var.admin_username

}  administrator_login_password  = random_password.sql_admin.result

  minimum_tls_version           = "1.2"

# Store SQL Admin Password in Key Vault  public_network_access_enabled = false

resource "azurerm_key_vault_secret" "sql_admin_password" {

  count        = var.key_vault_id != null ? 1 : 0  azuread_administrator {

  name         = "sql-admin-password-${var.prefix}"    login_username = var.azuread_admin_login

  value        = var.administrator_password != null ? var.administrator_password : random_password.sql_admin.result    object_id      = var.azuread_admin_object_id

  key_vault_id = var.key_vault_id    tenant_id      = data.azurerm_client_config.current.tenant_id

  content_type = "SQL Admin Password"  }



  depends_on = [azurerm_mssql_server.main]  identity {

}    type = "SystemAssigned"

  }

# SQL Database

resource "azurerm_mssql_database" "main" {  tags = local.common_tags

  name                 = var.database_name

  server_id            = azurerm_mssql_server.main.id  lifecycle {

  collation            = "SQL_Latin1_General_CP1_CI_AS"    ignore_changes = [

  sku_name             = var.sku_name      administrator_login_password,

  max_size_gb          = var.max_size_gb      tags["CreatedDate"]

  zone_redundant       = var.zone_redundant    ]

  geo_backup_enabled   = var.geo_backup_enabled  }

  storage_account_type = var.backup_storage_redundancy}



  short_term_retention_policy {# Store SQL Admin Password in Key Vault

    retention_days           = var.short_term_retention_daysresource "azurerm_key_vault_secret" "sql_admin_password" {

    backup_interval_in_hours = 12  name         = "sql-admin-password"

  }  value        = random_password.sql_admin.result

  key_vault_id = var.key_vault_id

  long_term_retention_policy {  content_type = "SQL Admin Password"

    weekly_retention  = var.weekly_backup_retention

    monthly_retention = var.monthly_backup_retention  depends_on = [azurerm_mssql_server.main]

    yearly_retention  = var.yearly_backup_retention}

    week_of_year      = 1

  }# SQL Database

resource "azurerm_mssql_database" "main" {

  threat_detection_policy {  name                        = var.database_name

    state                = "Enabled"  server_id                   = azurerm_mssql_server.main.id

    email_account_admins = var.threat_detection_email_account_admins  collation                   = "SQL_Latin1_General_CP1_CI_AS"

    email_addresses      = var.threat_detection_email_addresses  sku_name                    = var.sku_name

    retention_days       = 30  max_size_gb                 = var.max_size_gb

  }  zone_redundant              = var.zone_redundant

  geo_backup_enabled          = true

  tags = merge(  ledger_enabled              = false

    var.tags,  storage_account_type        = var.backup_storage_redundancy

    {

      environment = var.prefix  short_term_retention_policy {

    }    retention_days           = var.short_term_retention_days

  )    backup_interval_in_hours = 12

}  }



# Transparent Data Encryption with CMK (optional)  long_term_retention_policy {

resource "azurerm_mssql_server_transparent_data_encryption" "main" {    weekly_retention  = var.weekly_backup_retention

  count            = var.tde_key_vault_key_id != null ? 1 : 0    monthly_retention = var.monthly_backup_retention

  server_id        = azurerm_mssql_server.main.id    yearly_retention  = var.yearly_backup_retention

  key_vault_key_id = var.tde_key_vault_key_id    week_of_year      = 1

}  }



# SQL Auditing (optional)  threat_detection_policy {

resource "azurerm_mssql_server_extended_auditing_policy" "main" {    state                      = "Enabled"

  count                                   = var.log_analytics_workspace_id != null ? 1 : 0    email_account_admins       = "Enabled"

  server_id                               = azurerm_mssql_server.main.id    email_addresses            = var.security_alert_emails

  log_analytics_workspace_id              = var.log_analytics_workspace_id    retention_days             = 30

  storage_account_access_key_is_secondary = false    storage_endpoint           = var.storage_endpoint

  retention_in_days                       = 90    storage_account_access_key = var.storage_access_key

  log_monitoring_enabled                  = true  }

}

  tags = local.common_tags

resource "azurerm_mssql_database_extended_auditing_policy" "main" {

  count                                   = var.log_analytics_workspace_id != null ? 1 : 0  lifecycle {

  database_id                             = azurerm_mssql_database.main.id    ignore_changes = [tags["CreatedDate"]]

  log_analytics_workspace_id              = var.log_analytics_workspace_id  }

  storage_account_access_key_is_secondary = false}

  retention_in_days                       = 90

  log_monitoring_enabled                  = true# Transparent Data Encryption

}resource "azurerm_mssql_server_transparent_data_encryption" "main" {

  server_id        = azurerm_mssql_server.main.id

# Private Endpoint  key_vault_key_id = var.tde_key_vault_key_id

resource "azurerm_private_endpoint" "sql" {}

  count               = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${azurerm_mssql_server.main.name}"# SQL Auditing

  location            = var.locationresource "azurerm_mssql_server_extended_auditing_policy" "main" {

  resource_group_name = var.resource_group_name  server_id                               = azurerm_mssql_server.main.id

  subnet_id           = var.private_endpoint_subnet_id  storage_endpoint                        = var.storage_endpoint

  storage_account_access_key              = var.storage_access_key

  private_service_connection {  storage_account_access_key_is_secondary = false

    name                           = "psc-${azurerm_mssql_server.main.name}"  retention_in_days                       = 90

    private_connection_resource_id = azurerm_mssql_server.main.id  log_monitoring_enabled                  = true

    is_manual_connection           = false}

    subresource_names              = ["sqlServer"]

  }resource "azurerm_mssql_database_extended_auditing_policy" "main" {

  database_id                             = azurerm_mssql_database.main.id

  private_dns_zone_group {  storage_endpoint                        = var.storage_endpoint

    name                 = "pdz-group-sql"  storage_account_access_key              = var.storage_access_key

    private_dns_zone_ids = var.private_dns_zone_ids  storage_account_access_key_is_secondary = false

  }  retention_in_days                       = 90

  log_monitoring_enabled                  = true

  tags = var.tags}

}

# Private Endpoint

# SQL Security Alert Policyresource "azurerm_private_endpoint" "sql" {

resource "azurerm_mssql_server_security_alert_policy" "main" {  name                = "pe-${azurerm_mssql_server.main.name}"

  resource_group_name  = var.resource_group_name  location            = var.location

  server_name          = azurerm_mssql_server.main.name  resource_group_name = var.resource_group_name

  state                = "Enabled"  subnet_id           = var.private_endpoint_subnet_id

  email_account_admins = var.security_alert_email_account_admins

  email_addresses      = var.security_alert_email_addresses  private_service_connection {

  retention_days       = 30    name                           = "psc-${azurerm_mssql_server.main.name}"

}    private_connection_resource_id = azurerm_mssql_server.main.id

    is_manual_connection           = false

# SQL Vulnerability Assessment (optional)    subresource_names              = ["sqlServer"]

resource "azurerm_mssql_server_vulnerability_assessment" "main" {  }

  count                           = var.enable_vulnerability_assessment && var.storage_endpoint != null ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id  private_dns_zone_group {

  storage_container_path          = "${var.storage_endpoint}vulnerability-assessment/"    name                 = "pdz-group-sql"

  storage_account_access_key      = var.storage_access_key    private_dns_zone_ids = [var.private_dns_zone_sql_id]

  }

  recurring_scans {

    enabled                   = true  tags = local.common_tags

    email_subscription_admins = var.vulnerability_email_subscription_admins}

    emails                    = var.vulnerability_assessment_emails

  }# SQL Vulnerability Assessment

}resource "azurerm_mssql_server_vulnerability_assessment" "main" {

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id

# Diagnostic Settings  storage_container_path          = "${var.storage_endpoint}vulnerability-assessment/"

resource "azurerm_monitor_diagnostic_setting" "sql_server" {  storage_account_access_key      = var.storage_access_key

  count                      = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${azurerm_mssql_server.main.name}"  recurring_scans {

  target_resource_id         = azurerm_mssql_server.main.id    enabled                   = true

  log_analytics_workspace_id = var.log_analytics_workspace_id    email_subscription_admins = true

    emails                    = var.security_alert_emails

  metric {  }

    category = "AllMetrics"}

    enabled  = true

  }resource "azurerm_mssql_server_security_alert_policy" "main" {

}  resource_group_name        = var.resource_group_name

  server_name                = azurerm_mssql_server.main.name

resource "azurerm_monitor_diagnostic_setting" "sql_database" {  state                      = "Enabled"

  count                      = var.log_analytics_workspace_id != null ? 1 : 0  email_account_admins       = true

  name                       = "diag-${azurerm_mssql_database.main.name}"  email_addresses            = var.security_alert_emails

  target_resource_id         = azurerm_mssql_database.main.id  retention_days             = 30

  log_analytics_workspace_id = var.log_analytics_workspace_id  storage_endpoint           = var.storage_endpoint

  storage_account_access_key = var.storage_access_key

  enabled_log {}

    category = "SQLInsights"

  }# Diagnostic Settings

resource "azurerm_monitor_diagnostic_setting" "sql_server" {

  enabled_log {  name                       = "diag-${azurerm_mssql_server.main.name}"

    category = "AutomaticTuning"  target_resource_id         = azurerm_mssql_server.main.id

  }  log_analytics_workspace_id = var.log_analytics_workspace_id



  enabled_log {  metric {

    category = "QueryStoreRuntimeStatistics"    category = "AllMetrics"

  }    enabled  = true

  }

  enabled_log {}

    category = "QueryStoreWaitStatistics"

  }resource "azurerm_monitor_diagnostic_setting" "sql_database" {

  name                       = "diag-${azurerm_mssql_database.main.name}"

  enabled_log {  target_resource_id         = azurerm_mssql_database.main.id

    category = "Errors"  log_analytics_workspace_id = var.log_analytics_workspace_id

  }

  enabled_log {

  enabled_log {    category = "SQLInsights"

    category = "DatabaseWaitStatistics"  }

  }

  enabled_log {

  enabled_log {    category = "AutomaticTuning"

    category = "Timeouts"  }

  }

  enabled_log {

  enabled_log {    category = "QueryStoreRuntimeStatistics"

    category = "Blocks"  }

  }

  enabled_log {

  enabled_log {    category = "QueryStoreWaitStatistics"

    category = "Deadlocks"  }

  }

  enabled_log {

  metric {    category = "Errors"

    category = "AllMetrics"  }

    enabled  = true

  }  enabled_log {

}    category = "DatabaseWaitStatistics"

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