
prefix                    = "prod"
location                  = "eastus"
project_name              = "azureapp"
cost_center               = "IT-Production"
random_suffix             = "prod01"
aks_node_count            = 3
sql_administrator_login   = "sqladmin"
sql_administrator_password = "ChangeMe-prod-PleaseRotate123!"
sql_database_name         = "appdb"

# Add your Azure AD group/user object IDs below
# aks_admin_group_object_ids    = ["00000000-0000-0000-0000-000000000000"]
# keyvault_admin_object_ids     = ["00000000-0000-0000-0000-000000000000"]
