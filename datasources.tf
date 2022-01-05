data "azurerm_client_config" "current" {}

data "azurerm_storage_account" "straphael" {
    name = "${var.data["raphael"]["name"]}"
    resource_group_name = "${var.data["raphael"]["resource_group_name"]}"
}