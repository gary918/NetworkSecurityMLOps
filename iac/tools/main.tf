# A quick way to run the following commands:
# terraform init
# terraform state list
# terraform state rm xxx

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.7"
    }
  }

  required_version = ">= 0.14.9"

  backend "azurerm" {
    resource_group_name   = "s1216-ssdev-rg"
    storage_account_name  = "s1216aestrtfssdev"
    container_name        = "tfstate-cont"
    key                   = "svinfra.tfstate" 
    # key                   = "svinit.tfstate"
  }
}

provider "azurerm" {
  features {}
}
