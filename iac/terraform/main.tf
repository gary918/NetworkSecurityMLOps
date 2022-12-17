# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.36"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.7"
    }
  }

  required_version = ">= 0.14.9"

  backend "azurerm" {
    # resource_group_name   = "nsmlops-tf-rg"
    # storage_account_name  = "nsmlopstfsa"
    # container_name        = "tfstate-cont"
    # key                   = "nsmlops.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true

}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}