
prefix                    = "dev"
location                  = "eastus"
project_name              = "azureapp"
cost_center               = "IT-Development"
random_suffix             = "dev01"
aks_node_count            = 2
sql_administrator_login   = "sqladmin"
sql_database_name         = "appdb"

# Sensitive values must be provided via environment variables (GitHub Secrets):
# TF_VAR_sql_administrator_password - Set as GitHub Environment Secret
# TF_VAR_aks_admin_group_object_ids - Set as GitHub Environment Secret (JSON array: ["guid1","guid2"])
# TF_VAR_keyvault_admin_object_ids  - Set as GitHub Environment Secret (JSON array: ["guid1","guid2"])
