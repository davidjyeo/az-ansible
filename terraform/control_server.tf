resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

data "local_file" "setup_script" {
  filename = "${path.module}/../scripts/ubuntu-setup.sh"
}

module "control" {
  source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  admin_username                     = "localmgr"
  enable_telemetry                   = var.enable_telemetry
  disable_password_authentication    = true
  location                           = azurerm_resource_group.rg.location
  name                               = "control"
  resource_group_name                = azurerm_resource_group.rg.name
  os_type                            = "Linux"
  sku_size                           = "Standard_D2ds_v5"
  zone                               = null
  timezone                           = "GMT Standard Time"
  generate_admin_password_or_ssh_key = false

  user_data = base64encode(data.local_file.setup_script.content)
  # custom_data = base64encode(data.local_file.setup_script.content)

  admin_ssh_keys = [
    {
      public_key = tls_private_key.ssh.public_key_openssh # if using ecdsa, ecdsa_curve must be >= P256
      username   = "localmgr"                             # the username must match the admin_username currently.
    }
  ]

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uai.id]
  }

  network_interfaces = {
    network_interface_1 = {
      name                           = "nic-control"
      accelerated_networking_enabled = true

      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-control-ipconfig"
          private_ip_subnet_resource_id = azurerm_subnet.ansible_subnet.id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.ansible_subnet.address_prefixes[0], 4)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    name                 = "dsk-control-osDisk"
  }

  data_disk_managed_disks = {
    for i in range(0) : format("disk-%02d", i + 1) => {
      name                       = format("dsk-control-dataDisk-%02d", i + 1)
      storage_account_type       = var.storage_account_type
      create_option              = "Empty"
      disk_size_gb               = 64
      on_demand_bursting_enabled = var.storage_account_type == "Premium_LRS" ? true : false
      # performance_plus_enabled   = true
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
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # source_image_reference = {
  #   publisher = "RedHat"
  #   offer     = "RHEL"
  #   sku       = "9-lvm-gen2" #"94_gen2"
  #   version   = "latest"
  # }

  # tags = local.common.tags

}
