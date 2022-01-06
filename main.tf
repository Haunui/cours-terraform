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
  storage_account_name  = each.value.st.type == "resource" ? azurerm_storage_account.st0["${each.value.st.value}"].name : data.azurerm_storage_account.st0["${each.value.st.value}"].name
  container_access_type = "${each.value.container_access_type}"
}



###############
## KEY VAULT ##
###############

resource "azurerm_key_vault" "kv0" {
  for_each                    = var.resource.keyvault

  name                        = "${var.prefix.keyvault}${each.value.name}"
  resource_group_name         = azurerm_resource_group.rg0["${each.value.rg}"].name
  location                    = azurerm_resource_group.rg0["${each.value.rg}"].location
  enabled_for_disk_encryption = each.value.enabled_for_disk_encryption
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = each.value.soft_delete_retention_days
  purge_protection_enabled    = each.value.purge_protection_enabled

  sku_name                    = "${each.value.sku_name}"

  access_policy {
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    object_id                   = data.azurerm_client_config.current.object_id

    key_permissions             = each.value.access_policy.key_permissions
    secret_permissions          = each.value.access_policy.secret_permissions
    storage_permissions         = each.value.access_policy.storage_permissions
  }

  network_acls {
    bypass                      = each.value.network_acls.bypass
    default_action              = each.value.network_acls.default_action
    ip_rules                    = each.value.network_acls.ip_rules
    virtual_network_subnet_ids  = each.value.network_acls.virtual_network_subnet_ids
  }
}



################################
## RANDOM PASSWORD GENERATION ##
################################

resource "random_password" "randpass0" {
  for_each         = var.resource.random_password

  length           = each.value.length
  special          = each.value.special
  override_special = "${each.value.override_special}"
  min_lower        = each.value.min_lower
  min_numeric      = each.value.min_numeric
  min_special      = each.value.min_special
  min_upper        = each.value.min_upper
}



##################
## MSSQL SERVER ##
##################

resource "azurerm_mssql_server" "mssql0" {
  for_each                     = var.resource.mssql

  name                         = "${var.prefix.mssql}${each.value.name}"
  resource_group_name          = azurerm_resource_group.rg0["${each.value.rg}"].name
  location                     = azurerm_resource_group.rg0["${each.value.rg}"].location
  version                      = "${each.value.version}"

  administrator_login          = "${each.value.administrator_login}"
  administrator_login_password = random_password.randpass0["${each.value.random_password}"].result
  minimum_tls_version          = "${each.value.minimum_tls_version}"

  tags                         = each.value.tags
}



####################
## MSSQL DATABASE ##
####################

resource "azurerm_mssql_database" "mssqldb0" {
  for_each                        = var.resource.mssqldb
  name                            = "${var.prefix.mssqldb}${each.value.name}"
  server_id                       = azurerm_mssql_server.mssql0["${each.value.mssql}"].id

  auto_pause_delay_in_minutes     = each.value.auto_pause_delay_in_minutes
  max_size_gb                     = each.value.max_size_gb
  min_capacity                    = each.value.min_capacity
  read_replica_count              = each.value.read_replica_count
  read_scale                      = each.value.read_scale
  sku_name                        = "${each.value.sku_name}"
  zone_redundant                  = each.value.zone_redundant
}