# PREFIX
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
        vm = "vm"
        netint = "netint"
        pub_ip = "ip"
        monitor_action_group = "ag"
        monitor_metric_alert = "alert"
    }
}


# DATA
variable "data" {
    type = any
    default = {
        rg = {

        }
        
        st = {
            raphael = {
                name = "storageraphael"
                resource_group_name = "rg-raphael"
            }
        }

        stsas = {
            main = {
                st = "main"

            https_only = true
            signed_version = "2022-01-06"

            resource_types = {
                service = true
                container = true
                object = true
            }

            services = {
                blob = true
                queue = false
                table = false
                file = false
            }

            start = "2022-01-06T00:00:00Z"
            expiry = "2022-01-10T00:00:00Z"

            permissions = {
                read = true
                write = true
                delete = true
                list = true
                add = true
                create = true
                update = true
                process = true
            }
            }
        }
    }
}


# RESOURCE
variable "resource" {
    type = any
    default = {
        rg = {
            "main" = {
                name = "haunui"
                location = "West Europe"
            }
        }


        storage = {
            main = {
                name = "haunui"
                rg = "main"
                account_tier = "Standard"
                account_replication_type = "LRS"
                access_tier = "Cool"
            }

            mssql = {
                name = "haunuimssql"
                rg = "main"
                account_tier = "Standard"
                account_replication_type = "LRS"
                access_tier = "Cool"
            }
        }

        storage_network_rules = {
            main = {
                rg = "main"
                st = "main"
                bypass = ["AzureServices"]
                default_action = "Deny"
                ip_rules = ["78.118.201.29"]
                virtual_network_subnet_ids = []
            }
        }


        container = {
            main = {
                st = {
                    type = "resource"
                    value = "main"
                }

                name = "haunui"
                container_access_type = "private"
            }

            raphael = {
                st = {
                    type = "data"
                    value = "raphael"
                }

                name = "raphael"
                container_access_type = "private"
            }
        }

        keyvault = {
            main = {
                rg = "main"

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
                    virtual_network_subnet_ids = []
                }
            }
        }

        random_password = {
            mssql = {
                length = 20
                special = true
                override_special = "_%@"
                min_lower = 1
                min_numeric = 1
                min_special = 1
                min_upper = 1
            }
        }

        mssql = {
            main = {
                rg = "main"
                kv = "main"

                name = "haunui"
                version = "12.0"
                administrator_login = "HaunuiSS"
                random_password = "mssql"
                minimum_tls_version = "1.2"

                tags = { environment = "production" }
            }
        }

        mssqldb = {
            main = {
                mssql = "main"

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

        log = {
            main = {
                rg = "main"

                name = "haunui"
                sku = "PerGB2018"
                retention_in_days = 30
            }
        }

        diag = {
            main = {
                kv = "main"
                log = "main"

                name = "haunui - Envoie des logs"
                
                logs = [{
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
                rg = "main"

                name = "haunui"
                address = "10.0.0.0/16"

                subnet = {
                    "01" = "10.0.1.0/24"
                    "02" = "10.0.2.0/24"
                }
            }
        }

        subnet = {
            main01 = {
                rg = "main"
                vnet = "main"

                address_prefixes = [
                    "10.0.1.0/24",
                ]

                enforce_private_link_endpoint_network_policies = true
                enforce_private_link_service_network_policies = true
                service_endpoints = ["Microsoft.KeyVault","Microsoft.Storage"]
            }

            main02 = {
                rg = "main"
                vnet = "main"

                address_prefixes = [
                    "10.0.2.0/24"
                ]

                enforce_private_link_endpoint_network_policies = true
                enforce_private_link_service_network_policies = true
                service_endpoints = ["Microsoft.KeyVault","Microsoft.Storage"]
            }
        }

        netadapter = {
            main = {
                rg = "main"
                subnet = "main01"
                kv = "main"
                
                name = "haunui"

                private_service_connection = {
                    subresource_names = ["Vault"]
                    is_manual_connection = false
                }
            }
        }

        netint = {
            main = {
                rg = "main"
                subnet = "main01"

                name = "haunui"
                private_ip_address_allocation = "Dynamic"
            }
        }

        pub_ip = {
            # main = {
            #     rg = "main"

            #     name = "haunui"
            #     allocation_method = "Static"

            #     tags = { environment = "Production" }
            # }
        }

        vm = {
            main = {
                rg = "main"
                netint = "main"

                name = "haunui"
                vm_size = "Standard_B1ls"

                image = {
                    publisher = "Canonical"
                    offer = "UbuntuServer"
                    sku = "18.04-LTS"
                    version = "latest"
                }

                disk = [
                    {
                        name = "disk0"
                        caching = "ReadWrite"
                        create_option = "FromImage"
                        managed_disk_type = "Standard_LRS"
                    }
                ]

                os_profile = {
                    computer_name = "vm1"
                    admin_username = "MyNameIsAdmin"
                    admin_password = "P@ssW0rd123!"
                }

                os_profile_linux_config = {
                    disable_password_authentication = false
                }

                tags = {
                    environment = "staging"
                }
            }
        }

        monitor_action_group = {
            critical0 = {
                rg = "main"

                name = "haunui"
                short_name = "crit0"

                email_receiver = [
                    {
                        name = "Haunui"
                        email_address = "haunui@saint-sevin.fr"
                    }
                ]
            }
        }

        monitor_metric_alert = {
            vm0_cpu = {
                rg = "main"
                vm = "main"
                description = "Alert when CPU usage is greater than 80%"
                target_resource_type = "Microsoft.Compute/virtualMachines"

                criteria = {
                    metric_namespace = "Microsoft.Compute/virtualMachines"
                    metric_name = "Percentage CPU"
                    aggregation = "Total"
                    operator = "GreaterThan"
                    threshold = 80
                }

                action_group = "critical0"
            }
        }
    }
}