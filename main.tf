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

# resource "azurerm_mssql_database" "mssqldb0" {
#   for_each                        = var.resource.mssqldb
#   name                            = "${var.prefix.mssqldb}${each.value.name}"
#   server_id                       = azurerm_mssql_server.mssql0["${each.value.mssql}"].id

#   auto_pause_delay_in_minutes     = each.value.auto_pause_delay_in_minutes
#   max_size_gb                     = each.value.max_size_gb
#   min_capacity                    = each.value.min_capacity
#   read_replica_count              = each.value.read_replica_count
#   read_scale                      = each.value.read_scale
#   sku_name                        = "${each.value.sku_name}"
#   zone_redundant                  = each.value.zone_redundant
# }



##############################################
## STORE MSSQL SERVER PASSWORD IN KEY VAULT ##
##############################################

resource "azurerm_key_vault_secret" "mssqlsecret0" {
  for_each     = var.resource.mssql

  name         = "${var.prefix.mssql}${each.value.name}adminpassword"
  value        = random_password.randpass0["${each.value.random_password}"].result
  key_vault_id = azurerm_key_vault.kv0["${each.value.kv}"].id
}



#############################
## LOG ANALYTICS WORKSPACE ##
#############################

resource "azurerm_log_analytics_workspace" "log0" {
  for_each            = var.resource.log
  name                = "${var.prefix.log}${each.value.name}"
  resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
  location            = azurerm_resource_group.rg0["${each.value.rg}"].location
  sku                 = "${each.value.sku}"
  retention_in_days   = each.value.retention_in_days
}



################################
## MONITOR DIAGNOSTIC SETTING ##
################################

resource "azurerm_monitor_diagnostic_setting" "diag0" {
  for_each                   = var.resource.diag

  name                       = "${var.prefix.diag}${each.value.name}"
  target_resource_id         = azurerm_key_vault.kv0["${each.value.kv}"].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log0["${each.value.log}"].id

  log {
    category = "${each.value.logs[0].category}"
    enabled  = each.value.logs[0].enabled

    retention_policy {
      enabled = each.value.logs[0].retention_policy.enabled
    }
  }

  log {
    category = "${each.value.logs[1].category}"
    enabled  = each.value.logs[1].enabled

    retention_policy {
      enabled = each.value.logs[1].retention_policy.enabled
    }
  }

  metric {
    category = "${each.value.metric.category}"

    retention_policy {
      enabled = each.value.metric.retention_policy.enabled
    }
  }
}



#####################
## VIRTUAL NETWORK ##
#####################

resource "azurerm_virtual_network" "vnet0" {
  for_each            = var.resource.vnet

  name                = "${var.prefix.vnet}${each.value.name}"
  address_space       = ["${each.value.address}"]
  resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
  location            = azurerm_resource_group.rg0["${each.value.rg}"].location
}



#################
## SUB NETWORK ##
#################

resource "azurerm_subnet" "subnet0" {
  for_each             = var.resource.subnet

  name                 = "${var.prefix.subnet}${each.key}"
  resource_group_name  = azurerm_resource_group.rg0["${each.value.rg}"].name
  virtual_network_name = azurerm_virtual_network.vnet0["${each.value.vnet}"].name
  address_prefixes     = each.value.address_prefixes

  enforce_private_link_endpoint_network_policies  = each.value.enforce_private_link_endpoint_network_policies
  enforce_private_link_service_network_policies   = each.value.enforce_private_link_service_network_policies
  service_endpoints                               = each.value.service_endpoints
}



##############
## ENDPOINT ##
##############

resource "azurerm_private_endpoint" "netadapter0" {
  for_each            = var.resource.netadapter

  name                = "${var.prefix.netadapter}${each.value.name}"
  resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
  location            = azurerm_resource_group.rg0["${each.value.rg}"].location
  subnet_id           = azurerm_subnet.subnet0["${each.value.subnet}"].id

  private_service_connection {
    name                            = "${var.prefix.netadapter}${each.value.name}conn"
    private_connection_resource_id  = azurerm_key_vault.kv0["${each.value.kv}"].id
    subresource_names               = each.value.private_service_connection.subresource_names
    is_manual_connection            = each.value.private_service_connection.is_manual_connection
  } 
}



#######################
## NETWORK INTERFACE ##
#######################

resource "azurerm_network_interface" "netint0" {
  for_each                        = var.resource.netint
  name                            = "${var.prefix.netint}${each.value.name}"
  resource_group_name             = azurerm_resource_group.rg0["${each.value.rg}"].name
  location                        = azurerm_resource_group.rg0["${each.value.rg}"].location

  ip_configuration {
    name                          = "${var.prefix.netint}${each.value.name}conf0"
    subnet_id                     = azurerm_subnet.subnet0["${each.value.subnet}"].id
    private_ip_address_allocation = "${each.value.private_ip_address_allocation}"
    #public_ip_address_id          = azurerm_public_ip.ipmain.id
  }
}



################
## PUBLIC IPs ##
################

# resource "azurerm_public_ip" "pub_ip0" {
#   for_each            = var.resource.pub_ip

#   name                = "${var.prefix.pub_ip}${each.value.name}"
#   resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
#   location            = azurerm_resource_group.rg0["${each.value.rg}"].location
#   allocation_method   = "${each.value.allocation_method}"

#   tags                = each.value.tags
# }



########
## VM ##
########

resource "azurerm_virtual_machine" "vm0" {
  for_each              = var.resource.vm

  name                  = "${var.prefix.vm}${each.value.name}"
  resource_group_name   = azurerm_resource_group.rg0["${each.value.rg}"].name
  location              = azurerm_resource_group.rg0["${each.value.rg}"].location
  network_interface_ids = [azurerm_network_interface.netint0["${each.value.netint}"].id]
  vm_size               = "${each.value.vm_size}"

  storage_image_reference {
    publisher           = "${each.value.image.publisher}"
    offer               = "${each.value.image.offer}"
    sku                 = "${each.value.image.sku}"
    version             = "${each.value.image.version}"
  }

  storage_os_disk {
    name                = "${each.value.disk[0].name}"
    caching             = "${each.value.disk[0].caching}"
    create_option       = "${each.value.disk[0].create_option}"
    managed_disk_type   = "${each.value.disk[0].managed_disk_type}"
  }

  os_profile {
    computer_name       = "${each.value.os_profile.computer_name}"
    admin_username      = "${each.value.os_profile.admin_username}"
    admin_password      = "${each.value.os_profile.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${each.value.os_profile_linux_config.disable_password_authentication}"
  }

  tags = each.value.tags
}



##########################
## MONITOR ACTION GROUP ##
##########################

resource "azurerm_monitor_action_group" "monitorag0" {
  for_each            = var.resource.monitor_action_group

  name                = "${var.prefix.monitor_action_group}${each.value.name}${each.key}"
  resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
  short_name          = "${each.value.short_name}"

  email_receiver {
    name          = "${each.value.email_receiver[0].name}"
    email_address = "${each.value.email_receiver[0].email_address}"
  }

  email_receiver {
    name          = "${each.value.email_receiver[1].name}"
    email_address = "${each.value.email_receiver[1].email_address}"
  }
}



##########################
## MONITOR METRIC ALERT ## 
##########################

resource "azurerm_monitor_metric_alert" "alert" {
  for_each = var.resource.monitor_metric_alert

  name = "${var.prefix.monitor_metric_alert}${each.key}"
  resource_group_name = azurerm_resource_group.rg0["${each.value.rg}"].name
  scopes = [azurerm_virtual_machine.vm0["${each.value.vm}"].id]
  description = "${each.value.description}"
  target_resource_type = "${each.value.target_resource_type}"

  criteria {
    metric_namespace = "${each.value.criteria.metric_namespace}"
    metric_name = "${each.value.criteria.metric_name}"
    aggregation = "${each.value.criteria.aggregation}"
    operator = "${each.value.criteria.operator}"
    threshold = each.value.criteria.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitorag0["${each.value.action_group}"].id
  }
}