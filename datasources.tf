# CLIENT CONFIG FOR KEY VAULT
data "azurerm_client_config" "current" {}


# DATASOURCE RESOURCE GROUP
data "azurerm_storage_account" "rg0" {
  for_each = var.data.rg

  name = "${each.value.name}"
  resource_group_name = "${each.value.resource_group_name}"
}

# DATASOURCE STORAGE
data "azurerm_storage_account" "st0" {
  for_each = var.data.st

  name = "${each.value.name}"
  resource_group_name = "${each.value.resource_group_name}"
}