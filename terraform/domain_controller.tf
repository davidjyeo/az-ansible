module "dc01" {
  source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  admin_username                     = "localmgr"
  admin_password                     = "1QAZ2wsx3edc"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  location                           = azurerm_resource_group.rg.location
  name                               = "vmansadvuks01"
  resource_group_name                = azurerm_resource_group.rg.name
  virtualmachine_os_type             = "Windows"
  virtualmachine_sku_size            = "Standard_B2as_v2"
  zone                               = null

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uai.id]
  }

  network_interfaces = {
    network_interface_1 = {
      name                           = "nic-vmansadvuks01"
      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-vmansadvuks01-ipconfig"
          private_ip_subnet_resource_id = azurerm_subnet.SN-Workload.id
          private_ip_address_allocation = "Static" #"Dynamic" # 
          private_ip_address            = cidrhost(azurerm_subnet.SN-Workload.address_prefixes[0], 4)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "dsk-vmansadvuks01-osDisk"
  }

  data_disk_managed_disks = {
    for i in range(2) : format("dsk-%02d", i + 1) => {
      name                 = format("dsk-vmansadvuks01-dataDisk-%02d", i + 1)
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
  #     scope_resource_id          = module.keyvault.resource_id
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

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk-g2"
    # publisher = "MicrosoftWindowsDesktop"
    # offer     = "Windows-11"
    # sku       = "win11-23h2-ent"
    version = "latest"
  }

  tags = local.common.tags
}
