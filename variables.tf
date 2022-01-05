variable "prefix" {
    type = map
    default = {
        rg = "rg-"
        storage = "storage"
        container = "container"
        keyvault = "keyvault"
        mssql = "mssql"
        mssqldb = "mssqldb"
        log = "acctest"
        diag = "diag "
        vnet = "vnet"
        subnet = "subnet"
        netadapter = "netadapter"
    }
}



variable "data" {
    type = map
    default = {
        raphael = {
            name = "storageraphael"
            resource_group_name = "rg-raphael"
        }
    }
}



variable "resource" {
    type = any
    default = {
        rg = {
            main = {
                name = "haunui"
                location = "West Europe"
            }
        }


        storage = {
            main = {
                name = "haunui"
                account_tier = "Standard"
                account_replication_type = "LRS"
                access_tier =  "Cool"
            }
            
            mssql = {
                name = "haunuimssql"
                account_tier = "Standard"
                account_replication_type = "LRS"
                access_tier = "Cool"
            }
        }


        container = {
            main = {
                name = "haunui"
                container_access_type = "private"
            }

            raphael = {
                name = "raphael"
                container_access_type = "private"
            }
        }

        keyvault = {
            main = {
                name = "haunui"
                enabled_for_disk_encryption = true
                soft_delete_retention_days  = 7
                purge_protection_enabled    = false
                sku_name = "standard"
                
                access_policy = {
                    key_permissions     = ["backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapkey", "update", "verify", "wrapkey"]
                    secret_permissions  = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
                    storage_permissions = ["backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update"]
                }
                
                network_acls = {
                    bypass = "AzureServices"
                    default_action = "Deny"
                    ip_rules = ["78.118.201.29"]
                }
            }
        }

        mssql = {
            main = {
                name = "haunui"
                version = "12.0"
                administrator_login = "HaunuiSS"
                minimum_tls_version = "1.2"

                tags = { environment = "production" }
            }
        }

        mssqldb = {
            main = {
                name = "haunui"
                auto_pause_delay_in_minutes = 120
                max_size_gb = 1
                min_capacity = 0.5
                read_replica_count = 0
                read_scale = false
                sku_name = "GP_S_Gen5_1"
                zone_redundant = false
            }
        }

        mssqladmin = {
            secret = {
                name = "mssqladminpassword"
            }

            password = {
                length = 20
                special = true
                override_special = "_%@"
                min_lower = 1
                min_numeric = 1
                min_special = 1
                min_upper = 1
            }
        }

        log = {
            main = {
                name = "haunui"
                sku = "PerGB2018"
                retention_in_days = 30
            }
        }

        diag = {
            main = {
                name = "haunui - Envoie des logs"
                
                log = [{
                    category = "AuditEvent"
                    enabled = false

                    retention_policy = {
                        enabled = true
                    }
                },
                {
                    category = "AzurePolicyEvaluationDetails"
                    enabled = true

                    retention_policy = {
                        enabled = true
                    }
                }]

                metric = {
                    category = "AllMetrics"
                    
                    retention_policy = {
                        enabled = true
                    }
                }
            }
        }

        vnet = {
            main = {
                name = "haunui"
                address = "10.0.0.0/16"

                subnet = {
                    "01" = "10.0.1.0/24"
                    "02" = "10.0.2.0/24"
                }
            }
        }

        netadapter = {
            main = {
                name = "haunui"

                private_service_connection = {
                    subresource_names = ["Vault"]
                    is_manual_connection = false
                }
            }
        }


    }
}