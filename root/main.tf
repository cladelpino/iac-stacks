terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # CI principal cannot auto-register resource providers; rely on pre-registered RPs.
  resource_provider_registrations = "none"
}
