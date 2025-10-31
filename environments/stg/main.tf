
locals {
  spokes = {
    workload = { address_space = ["10.1.0.0/16"] }
  }

  common_tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = var.project_name
    CostCenter  = var.cost_center
  }
}

# Monitoring (must be created first)
module "monitoring" {
  source              = "../../modules/monitoring"
  prefix              = var.prefix
  location            = var.location
  resource_group_name = module.network.hub_rg_name
  retention_in_days   = 30
  tags                = local.common_tags

  depends_on = [module.network]
}

# Networking with hub-spoke topology
module "network" {
  source            = "../../modules/networking"
  prefix            = var.prefix
  location          = var.location
  hub_address_space = ["10.0.0.0/16"]
  spokes            = local.spokes
  tags              = local.common_tags
}

# Storage for tfstate and other purposes
module "storage" {
  source                      = "../../modules/storage"
  name                        = lower("${var.prefix}tfstateacct${var.random_suffix}")
  location                    = var.location
  resource_group_name         = module.network.hub_rg_name
  account_tier                = "Standard"
  account_replication_type    = "LRS"
  private_endpoint_subnet_id  = module.network.pe_subnet_id
  private_dns_zone_blob_id    = module.network.private_dns_zone_storage_blob_id
  private_dns_zone_file_id    = module.network.private_dns_zone_storage_file_id
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  tags                        = local.common_tags
}

# Key Vault
module "keyvault" {
  source                     = "../../modules/keyvault"
  name                       = "${var.prefix}-kv-${var.random_suffix}"
  location                   = var.location
  resource_group_name        = module.network.hub_rg_name
  enable_rbac_authorization  = true
  private_endpoint_subnet_id = module.network.pe_subnet_id
  private_dns_zone_ids       = [module.network.private_dns_zone_keyvault_id]
  create_cmk_key             = true
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  admin_object_ids           = var.keyvault_admin_object_ids
  tags                       = local.common_tags
}

# Application Gateway in hub
module "appgw" {
  source                     = "../../modules/application-gateway"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.network.hub_rg_name
  subnet_id                  = module.network.appgw_subnet_id
  autoscale_min_capacity     = 1
  autoscale_max_capacity     = 3
  waf_mode                   = "Prevention"
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.common_tags
}

# AKS in workload spoke
module "aks" {
  source                     = "../../modules/aks"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.network.spoke_rg["workload"].name
  subnet_id                  = module.network.spoke_aks_subnet_ids["workload"]
  node_count                 = var.aks_node_count
  vm_size                    = "Standard_D4s_v3"
  enable_auto_scaling        = true
  min_count                  = 2
  max_count                  = 5
  private_cluster_enabled    = true
  private_dns_zone_id        = module.network.private_dns_zone_aks_id
  enable_agic                = true
  application_gateway_id     = module.appgw.appgw_id
  appgw_resource_group_name  = module.network.hub_rg_name
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  admin_group_object_ids     = var.aks_admin_group_object_ids
  enable_user_node_pool      = true
  user_node_pool_count       = 2
  user_node_pool_min_count   = 2
  user_node_pool_max_count   = 10
  tags                       = local.common_tags
}

# SQL Server & Database
module "sql" {
  source                     = "../../modules/sql-database"
  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.network.spoke_rg["workload"].name
  administrator_login        = var.sql_administrator_login
  administrator_password     = var.sql_administrator_password
  database_name              = var.sql_database_name
  sku_name                   = "S0"
  max_size_gb                = 50
  private_endpoint_subnet_id = module.network.spoke_db_subnet_ids["workload"]
  private_dns_zone_ids       = [module.network.private_dns_zone_sql_id]
  key_vault_id               = module.keyvault.keyvault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.common_tags

  depends_on = [module.keyvault]
}

# Front Door using appgw public IP as backend
module "frontdoor" {
  source                     = "../../modules/frontdoor"
  prefix                     = var.prefix
  resource_group_name        = module.network.hub_rg_name
  backend_hostname           = module.appgw.appgw_public_ip
  sku_name                   = "Standard_AzureFrontDoor"
  waf_mode                   = "Prevention"
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.common_tags
}
