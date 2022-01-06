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



#########################
## MAIN RESOURCE GROUP ##
#########################

resource "azurerm_resource_group" "rgmain" {
  name     = "${var.prefix.rg}${var.resource.rg.main.name}"
  location = "${var.resource.rg.main.location}"
}



################################
## RESOURCE GROUPS WITH COUNT ##
################################

resource "azurerm_resource_group" "rgX" {
  count = 4
  name     = "rg-haunui-${count.index}"
  location = "West Europe"
}



##################
## MAIN STORAGE ##
##################

resource "azurerm_storage_account" "stmain" {
  name                     = "${var.prefix.storage}${var.resource.storage.main.name}"
  resource_group_name      = azurerm_resource_group.rgmain.name
  location                 = azurerm_resource_group.rgmain.location
  account_tier             = "${var.resource.storage.main.account_tier}"
  account_replication_type = "${var.resource.storage.main.account_replication_type}"
  access_tier              = "${var.resource.storage.main.access_tier}"
}



################################
## MAIN STORAGE NETWORK RULES ##
################################

resource "azurerm_storage_account_network_rules" "stmainnetworkrules" {
  resource_group_name        = azurerm_resource_group.rgmain.name
  storage_account_name       = azurerm_storage_account.stmain.name

  bypass                     = var.resource.storage.main.network_acls.bypass
  default_action             = var.resource.storage.main.network_acls.default_action
  ip_rules                   = var.resource.storage.main.network_acls.ip_rules
  virtual_network_subnet_ids = [azurerm_subnet.subnet0X["01"].id]
}



###################
## MSSQL STORAGE ##
###################

resource "azurerm_storage_account" "stmssql" {
  name                     = "${var.prefix.storage}${var.resource.storage.mssql.name}"
  resource_group_name      = azurerm_resource_group.rgmain.name
  location                 = azurerm_resource_group.rgmain.location
  account_tier             = "${var.resource.storage.mssql.account_tier}"
  account_replication_type = "${var.resource.storage.mssql.account_replication_type}"
  access_tier              = "${var.resource.storage.mssql.access_tier}"
}



####################
## MAIN CONTAINER ##
####################

resource "azurerm_storage_container" "contmain" {
  name                  = "${var.prefix.container}${var.resource.container.main.name}"
  storage_account_name  = azurerm_storage_account.stmain.name
  container_access_type = "${var.resource.container.main.container_access_type}"
}



#######################
## RAPHAEL CONTAINER ##
#######################

# resource "azurerm_storage_container" "cont-raphael" {
#   name                  = "${var.prefix.container}${var.resource.container.raphael.name}"
#   storage_account_name  = data.azurerm_storage_account.straphael.name
#   container_access_type = "${var.resource.container.raphael.container_access_type}"
# }



###############
## KEY VAULT ##
###############

resource "azurerm_key_vault" "kvmain" {
  name                        = "${var.prefix.keyvault}${var.resource.keyvault.main.name}"
  location                    = azurerm_resource_group.rgmain.location
  resource_group_name         = azurerm_resource_group.rgmain.name
  enabled_for_disk_encryption = var.resource.keyvault.main.enabled_for_disk_encryption
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.resource.keyvault.main.soft_delete_retention_days
  purge_protection_enabled    = var.resource.keyvault.main.purge_protection_enabled

  sku_name = "${var.resource.keyvault.main.sku_name}"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions             = var.resource.keyvault.main.access_policy.key_permissions
    secret_permissions          = var.resource.keyvault.main.access_policy.secret_permissions
    storage_permissions         = var.resource.keyvault.main.access_policy.storage_permissions
  }

  network_acls {
    bypass                      = var.resource.keyvault.main.network_acls.bypass
    default_action              = var.resource.keyvault.main.network_acls.default_action
    ip_rules                    = var.resource.keyvault.main.network_acls.ip_rules
    virtual_network_subnet_ids  = [azurerm_subnet.subnet0X["01"].id]
  }
}



##################
## MSSQL SERVER ##
##################

resource "azurerm_mssql_server" "mssqlmain" {
  name                = "${var.prefix.mssql}${var.resource.mssqladmin.secret.name}"
  resource_group_name = azurerm_resource_group.rgmain.name
  location            = azurerm_resource_group.rgmain.location
  version             = "${var.resource.mssql.main.version}"

  administrator_login          = "${var.resource.mssql.main.version}"
  administrator_login_password = random_password.mssqladminpassword.result
  minimum_tls_version          = "${var.resource.mssql.main.minimum_tls_version}"

  tags = var.resource.mssql.main.tags
}



####################
## MSSQL DATABASE ##
####################

# resource "azurerm_mssql_database" "mssqldbmain" {
#   name                            = "${var.prefix.mssqldb}${var.resource.mssqldb.main.name}"
#   server_id                       = azurerm_mssql_server.mssqlmain.id

#   auto_pause_delay_in_minutes     = var.resource.mssqldb.main.auto_pause_delay_in_minutes
#   max_size_gb                     = var.resource.mssqldb.main.max_size_gb
#   min_capacity                    = var.resource.mssqldb.main.min_capacity
#   read_replica_count              = var.resource.mssqldb.main.read_replica_count
#   read_scale                      = var.resource.mssqldb.main.read_scale
#   sku_name                        = "${var.resource.mssqldb.main.sku_name}"
#   zone_redundant                  = var.resource.mssqldb.main.zone_redundant
# }



################################
## RANDOM PASSWORD GENERATION ##
################################

resource "random_password" "mssqladminpassword" {
  length           = var.resource.mssqladmin.password.length
  special          = var.resource.mssqladmin.password.special
  override_special = "${var.resource.mssqladmin.password.override_special}"
  min_lower        = var.resource.mssqladmin.password.min_lower
  min_numeric      = var.resource.mssqladmin.password.min_numeric
  min_special      = var.resource.mssqladmin.password.min_special
  min_upper        = var.resource.mssqladmin.password.min_upper
}



###########################
## STORE RANDOM PASSWORD ##
###########################

resource "azurerm_key_vault_secret" "mssqladminsecret" {
  name         = "${var.resource.mssqladmin.secret.name}"
  value        = random_password.mssqladminpassword.result
  key_vault_id = azurerm_key_vault.kvmain.id
}



#############################
## LOG ANALYTICS WORKSPACE ##
#############################

resource "azurerm_log_analytics_workspace" "logmain" {
  name                = "${var.prefix.log}${var.resource.log.main.name}"
  location            = azurerm_resource_group.rgmain.location
  resource_group_name = azurerm_resource_group.rgmain.name
  sku                 = "${var.resource.log.main.sku}"
  retention_in_days   = var.resource.log.main.retention_in_days
}



################################
## MONITOR DIAGNOSTIC SETTING ##
################################

resource "azurerm_monitor_diagnostic_setting" "diagmain" {
  name                       = "${var.prefix.diag}${var.resource.diag.main.name}"
  target_resource_id         = azurerm_key_vault.kvmain.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logmain.id

  log {
    category = "${var.resource.diag.main.log[0].category}"
    enabled  = var.resource.diag.main.log[0].enabled

    retention_policy {
      enabled = var.resource.diag.main.log[0].retention_policy.enabled
    }
  }

  log {
    category = "${var.resource.diag.main.log[1].category}"
    enabled  = var.resource.diag.main.log[1].enabled

    retention_policy {
      enabled = var.resource.diag.main.log[1].retention_policy.enabled
    }
  }

  metric {
    category = "${var.resource.diag.main.metric.category}"

    retention_policy {
      enabled = var.resource.diag.main.metric.retention_policy.enabled
    }
  }
}



#####################
## VIRTUAL NETWORK ##
#####################

resource "azurerm_virtual_network" "vnetmain" {
  name                = "${var.prefix.vnet}${var.resource.vnet.main.name}"
  address_space       = ["${var.resource.vnet.main.address}"]
  location            = azurerm_resource_group.rgmain.location
  resource_group_name = azurerm_resource_group.rgmain.name
}



#################
## SUB NETWORK ##
#################

resource "azurerm_subnet" "subnet0X" {
  for_each             = var.resource.vnet.main.subnet
  name                 = "${var.prefix.subnet}${var.resource.vnet.main.name}${each.key}"
  resource_group_name  = azurerm_resource_group.rgmain.name
  virtual_network_name = azurerm_virtual_network.vnetmain.name
  address_prefixes     = ["${each.value}"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies = true
  service_endpoints = ["Microsoft.KeyVault","Microsoft.Storage"]
}



##############
## ENDPOINT ##
##############

resource "azurerm_private_endpoint" "netadaptermain" {
  name                = "${var.prefix.netadapter}${var.resource.netadapter.main.name}"
  location            = azurerm_resource_group.rgmain.location
  resource_group_name = azurerm_resource_group.rgmain.name
  subnet_id           = azurerm_subnet.subnet0X["01"].id

  private_service_connection {
    name                            = "${var.prefix.netadapter}${var.resource.netadapter.main.name}adapter"
    private_connection_resource_id  = azurerm_key_vault.kvmain.id
    subresource_names               = var.resource.netadapter.main.private_service_connection.subresource_names
    is_manual_connection            = var.resource.netadapter.main.private_service_connection.is_manual_connection
  } 
}



#######################
## NETWORK INTERFACE ##
#######################

resource "azurerm_network_interface" "netintmain" {
  name                            = "${var.prefix.netint}${var.resource.netint.main.name}"
  location                        = azurerm_resource_group.rgmain.location
  resource_group_name             = azurerm_resource_group.rgmain.name

  ip_configuration {
    name                          = "${var.prefix.netint}${var.resource.netint.main.name}conf0"
    subnet_id                     = azurerm_subnet.subnet0X["01"].id
    private_ip_address_allocation = "Static"
  }
}



########
## VM ##
########

resource "azurerm_virtual_machine" "vmmain" {
  name                  = "${var.prefix.vm}${var.resource.vm.main.name}"
  location              = azurerm_resource_group.rgmain.location
  resource_group_name   = azurerm_resource_group.rgmain.name
  network_interface_ids = [azurerm_network_interface.netintmain.id]
  vm_size               = "${var.resource.vm.main.vm_size}"

  storage_image_reference {
    publisher           = "${var.resource.vm.main.image.publisher}"
    offer               = "${var.resource.vm.main.image.offer}"
    sku                 = "${var.resource.vm.main.image.sku}"
    version             = "${var.resource.vm.main.image.version}"
  }

  storage_os_disk {
    name                = "${var.resource.vm.main.disk[0].name}"
    caching             = "${var.resource.vm.main.disk[0].caching}"
    create_option       = "${var.resource.vm.main.disk[0].create_option}"
    managed_disk_type   = "${var.resource.vm.main.disk[0].managed_disk_type}"
  }

  os_profile {
    computer_name       = "${var.resource.vm.main.os_profile.computer_name}"
    admin_username      = "${var.resource.vm.main.os_profile.admin_username}"
    admin_password      = "${var.resource.vm.main.os_profile.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment       = "staging"
  }
}