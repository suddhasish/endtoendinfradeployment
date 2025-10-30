
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-stg"
    storage_account_name = "sttfstatestg"
    container_name       = "tfstate"
    key                  = "stg.terraform.tfstate"
  }
}
