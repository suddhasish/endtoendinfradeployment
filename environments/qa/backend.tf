
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-qa"
    storage_account_name = "sttfstatewafqa"
    container_name       = "tfstate"
    key                  = "qa.terraform.tfstate"
  }
}
