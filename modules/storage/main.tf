
# Storage Account
resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  is_hns_enabled                  = var.is_hns_enabled

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }

  network_rules {
    default_action             = var.network_default_action
    bypass                     = ["AzureServices"]
    ip_rules                   = var.network_ip_rules
    virtual_network_subnet_ids = var.network_subnet_ids
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    var.tags,
    {
      environment = var.resource_group_name
    }
  )
}

# CMK Encryption (if key vault key provided)
resource "azurerm_storage_account_customer_managed_key" "cmk" {
  count              = var.cmk_key_vault_key_id != null ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id
  key_vault_id       = var.cmk_key_vault_id
  key_name           = var.cmk_key_name
}

# Storage Containers
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "additional" {
  for_each              = toset(var.additional_containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# Lifecycle Management Policy
resource "azurerm_storage_management_policy" "lifecycle" {
  count              = var.enable_lifecycle_policy ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "deleteOldSnapshots"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
    }
  }

  rule {
    name    = "tierOldBlobs"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}

# Private Endpoint for Blob
resource "azurerm_private_endpoint" "blob" {
  count               = var.private_endpoint_subnet_id != null ? 1 : 0
  name                = "pe-${azurerm_storage_account.this.name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.this.name}-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-blob"
    private_dns_zone_ids = [var.private_dns_zone_blob_id]
  }

  tags = var.tags
}

# Private Endpoint for File
resource "azurerm_private_endpoint" "file" {
  count               = var.private_endpoint_subnet_id != null && var.enable_file_share ? 1 : 0
  name                = "pe-${azurerm_storage_account.this.name}-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.this.name}-file"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-file"
    private_dns_zone_ids = [var.private_dns_zone_file_id]
  }

  tags = var.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${azurerm_storage_account.this.name}"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
