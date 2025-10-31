# terraform backend
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "sttfstatedev"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
