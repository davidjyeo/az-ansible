module "control" {
  source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  admin_username                     = "localmgr"
  admin_password                     = "Lloyds0fLondon"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  disable_password_authentication    = false
  location                           = azurerm_resource_group.rg.location
  name                               = "control"

  resource_group_name     = azurerm_resource_group.rg.name
  virtualmachine_os_type  = "Linux"
  virtualmachine_sku_size = "Standard_B2as_v2"
  zone                    = null

  # admin_ssh_keys = [
  #   {
  #     public_key = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).publicKey
  #     username   = "localmgr" #the username must match the admin_username currently.
  #   }
  # ]

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uai.id]
  }

  network_interfaces = {
    network_interface_1 = {
      name = "nic-control"

      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name = "nic-control-ipconfig"

          private_ip_subnet_resource_id = azurerm_subnet.ansible_subnet.id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.ansible_subnet.address_prefixes[0], 4)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "dsk-control-osDisk"

  }

  data_disk_managed_disks = {
    for i in range(0) : format("disk-%02d", i + 1) => {
      name = format("dsk-control-dataDisk-%02d", i + 1)

      storage_account_type = "StandardSSD_LRS"
      create_option        = "Empty"
      disk_size_gb         = 64
      # on_demand_bursting_enabled = var.TF_STORAGE_ACCOUNT_TYPE == "Premium_LRS" ? true : false
      # performance_plus_enabled = true
      lun     = i
      caching = "ReadWrite"
    }
  }

  shutdown_schedules = {
    standard_schedule = {
      daily_recurrence_time = "1900"
      timezone              = "GMT Standard Time"
      enabled               = true
      notification_settings = {
        enabled = false
      }
    }
  }

  # role_assignments_system_managed_identity = {
  #   role_assignment_1 = {
  #     scope_resource_id          = module.avm-res-keyvault-vault.resource.id
  #     role_definition_id_or_name = "Key Vault Secrets Officer"
  #     description                = "Assign the Key Vault Secrets Officer role to the virtual machine's system managed identity"
  #     principal_type             = "ServicePrincipal"
  #   }
  # }

  # role_assignments = {
  #   role_assignment_2 = {
  #     principal_id               = data.azurerm_client_config.current.client_id
  #     role_definition_id_or_name = "Virtual Machine Contributor"
  #     description                = "Assign the Virtual Machine Contributor role to the deployment user on this virtual machine resource scope."
  #     principal_type             = "ServicePrincipal"
  #   }
  # }

  allow_extension_operations = true

  extensions = {
    # AAD_SSH_Login_For_Linux = {
    #   name                       = "AADSSHLoginForLinux"
    #   publisher                  = "Microsoft.Azure.ActiveDirectory"
    #   type                       = "AADSSHLoginForLinux"
    #   type_handler_version       = "1.0"
    #   auto_upgrade_minor_version = true
    #   automatic_upgrade_enabled  = false
    #   settings                   = null
    # }
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts" #"0001-com-ubuntu-server-mantic"
    sku       = "server"           #"23_10-gen2"
    version   = "latest"
  }

  # source_image_reference = {
  #   publisher = "RedHat"
  #   offer     = "RHEL"
  #   sku       = "9-lvm-gen2" #"94_gen2"
  #   version   = "latest"
  # }

  tags = local.common.tags

}
