variable "resource_group_name" {
  type = string
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  storage_account_name = "beta"
}

resource "azurerm_storage_account" "sa" {
  name                     = local.storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false

  tags = {
    stack = "beta"
    env   = "test"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "beta-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

output "beta_storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "beta_container_name" {
  value = azurerm_storage_container.container.name
}
