terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }

  # Backend configuration should be defined in either config file
  # or passing in as environment variables during terraform init.
  #backend "azurerm" {}
}


provider "azurerm" {
  skip_provider_registration = true
  features {}
}
