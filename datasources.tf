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

# DATASOURCE STORAGE ACCOUNT SAS
data "azurerm_storage_account_sas" "saskey0" {
  for_each          = var.data.stsas

  connection_string = azurerm_storage_account.st0["${each.value.st}"].primary_connection_string
  https_only        = each.value.https_only
  #signed_version    = "${each.value.signed_version}"

  resource_types {
    service   = each.value.resource_types.service
    container = each.value.resource_types.container
    object    = each.value.resource_types.object
  }

  services {
    blob    = each.value.services.blob
    queue   = each.value.services.queue
    table   = each.value.services.table
    file    = each.value.services.file
  }

  start     = "${each.value.start}"
  expiry    = "${each.value.expiry}"

  permissions {
    read    = each.value.permissions.read
    write   = each.value.permissions.write
    delete  = each.value.permissions.delete
    list    = each.value.permissions.list
    add     = each.value.permissions.add
    create  = each.value.permissions.create
    update  = each.value.permissions.update
    process = each.value.permissions.process
  }
}


###############################

# GET STORAGE ACCOUNT URL
output "primary_connection_string" {
  value = nonsensitive("https://${azurerm_storage_account.st0["main"].name}.blob.core.windows.net/${data.azurerm_storage_account_sas.saskey0["main"].sas}")
  sensitive = false
}