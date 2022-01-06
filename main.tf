#######################
## DECLARE PROVIDERS ##
#######################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }

  }
}

provider "azurerm" {
  features {

  }
}



####################
## RESOURCE GROUP ##
####################

resource "azurerm_resource_group" "rg0" {
  for_each = var.resource.rg
  
  name     = "${var.prefix.rg}${each.value.name}"
  location = "${each.value.location}"
}



#############
## STORAGE ##
#############

resource "azurerm_storage_account" "st0" {
  for_each                 = var.resource.storage

  name                     = "${var.prefix.storage}${each.value.name}"
  resource_group_name      = azurerm_resource_group.rg0["${each.value.rg}"].name
  location                 = azurerm_resource_group.rg0["${each.value.rg}"].location
  account_tier             = "${each.value.account_tier}"
  account_replication_type = "${each.value.account_replication_type}"
  access_tier              = "${each.value.access_tier}"
}



###########################
## STORAGE NETWORK RULES ##
###########################

resource "azurerm_storage_account_network_rules" "stnetworkrules0" {
  for_each                   = var.resource.storage_network_rules

  resource_group_name        = azurerm_resource_group.rg0["${each.value.rg}"].name
  storage_account_name       = azurerm_storage_account.st0["${each.value.st}"].name

  bypass                     = each.value.bypass
  default_action             = each.value.default_action
  ip_rules                   = each.value.ip_rules
  virtual_network_subnet_ids = each.value.virtual_network_subnet_ids
}



####################
## MAIN CONTAINER ##
####################

resource "azurerm_storage_container" "cont0" {
  for_each              = var.resource.container

  name                  = "${var.prefix.container}${each.value.name}"
  storage_account_name  = azurerm_storage_account.st0["${each.value.st}"].name
  container_access_type = "${each.value.container_access_type}"
}