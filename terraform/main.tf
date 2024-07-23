### grant Key Vault Data Access Administrator to the SPN

# This allows us to randomize the region for the resource group.
# resource "random_integer" "region_index" {
#   max = length(module.regions.regions) - 1
#   min = 0
# }

resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = "UK South"
  # location = module.regions.regions[random_integer.region_index.result].name
  # tags = local.common.tags

}

# resource "azurerm_management_lock" "resource-group-level" {
#   name       = "resource-group-level"
#   scope      = azurerm_resource_group.rg.id
#   lock_level = "ReadOnly"
#   notes      = "This Resource Group is Read-Only"
# }

resource "azurerm_user_assigned_identity" "uai" {
  location            = azurerm_resource_group.rg.location
  name                = module.naming.user_assigned_identity.name
  resource_group_name = azurerm_resource_group.rg.name

  # tags = local.common.tags
}

# Fetch the public IP address using an HTTP request
data "http" "my_ip" {
  url = "https://api64.ipify.org?format=json"
}

module "avm-res-keyvault-vault" {
  source                          = "Azure/avm-res-keyvault-vault/azurerm"
  location                        = azurerm_resource_group.rg.location
  name                            = module.naming.key_vault.name
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enable_telemetry                = var.enable_telemetry
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  sku_name                        = "standard"
  public_network_access_enabled   = false

  network_acls = {
    bypass = "AzureServices"
    # ip_rules = [
    #   jsondecode(data.http.my_ip.body).ip
    #   # jsondecode(data.http.my_ip.response.body).ip
    # ]
  }

  keys = {
    azureuser-ssh-private-key = {
      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
      key_type = "EC"
      name     = "azureuser-ssh-private-key"
      # key_size = "P-256"
    }
  }

  # secrets = {
  #   azureuser-ssh-private-key = {
  #     name = "azureuser-ssh-private-key"
  #   }
  #   # azureuser-ssh-public-key = {
  #   #   name = "azureuser-ssh-public-key"
  #   # }
  # }
  # secrets_value = {
  #   azureuser-ssh-private-key = tls_private_key.this.private_key_pem
  #   # azureuser-ssh-public-key  = tls_private_key.this.public_key_openssh
  # }

  role_assignments = {
    deployment_user_secrets = { #give the deployment user access to secrets
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    deployment_user_keys = { #give the deployment user access to keys
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    user_managed_identity_keys = { #give the user assigned managed identity for the disk encryption set access to keys
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = azurerm_user_assigned_identity.uai.principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  wait_for_rbac_before_key_operations = {
    create = "60s"
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  # wait_for_rbac_before_contact_operations = 30
  # wait_for_rbac_before_key_operations     = 30
  # wait_for_rbac_before_secret_operations  = 30
}

resource "azurerm_virtual_network" "azfw_vnet" {
  name                = "${module.naming.virtual_network.name}-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  # tags = local.common.tags
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  address_prefixes     = ["10.0.1.0/26"]
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "VN-Spoke" {
  name                = "${module.naming.virtual_network.name}-spoke"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]

  # tags = local.common.tags
}

resource "azurerm_subnet" "SN-Workload" {
  name                 = module.naming.subnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VN-Spoke.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "ansible_subnet" {
  name                 = "${module.naming.subnet.name}-ansible"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VN-Spoke.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_virtual_network_peering" "hub-to-spoke" {
  name                      = "${azurerm_virtual_network.azfw_vnet.name}-to-${azurerm_virtual_network.VN-Spoke.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.azfw_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.VN-Spoke.id

  # allow_virtual_network_access = true
  # allow_forwarded_traffic      = true
  # allow_gateway_transit        = false
  # use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke-to-hub" {
  name                      = "${azurerm_virtual_network.VN-Spoke.name}-to-${azurerm_virtual_network.azfw_vnet.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.VN-Spoke.name
  remote_virtual_network_id = azurerm_virtual_network.azfw_vnet.id

  # allow_virtual_network_access = true
  # allow_forwarded_traffic      = true
  # allow_gateway_transit        = false
  # use_remote_gateways          = false
}


resource "azurerm_public_ip" "pip_azfw" {
  name                = module.naming.public_ip.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azfw" {
  name                = module.naming.firewall.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  threat_intel_mode   = "Deny"
  ip_configuration {
    name                 = module.naming.firewall_ip_configuration.name
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
}

resource "azurerm_firewall_policy" "azfw" {
  name                = module.naming.firewall_policy.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route_table" "rt" {
  name                = module.naming.route_table.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # disable_bgp_route_propagation = false
  bgp_route_propagation_enabled = true
  route {
    name                   = module.naming.route.name
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "subnet_rt_association" {
  subnet_id      = azurerm_subnet.SN-Workload.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "ansible_subnet_rt_association" {
  subnet_id      = azurerm_subnet.ansible_subnet.id
  route_table_id = azurerm_route_table.rt.id
}

# resource "azurerm_firewall_nat_rule_collection" "nat_rule_collection" {
#   name                = module.naming.firewall_nat_rule_collection.name
#   azure_firewall_name = azurerm_firewall.azfw.name
#   resource_group_name = azurerm_resource_group.rg.name
#   priority            = 200
#   action              = "Dnat"

#   rule {
#     name = "rdp-nat"
#     source_addresses = [
#       "*"
#     ]

#     destination_ports = [
#       "3389"
#     ]

#     destination_addresses = [
#       azurerm_public_ip.pip_azfw.ip_address
#     ]

#     translated_port    = 3389
#     translated_address = module.dc01.network_interfaces.network_interface_1.private_ip_address
#     protocols = [
#       "TCP"
#     ]
#   }
#   rule {
#     name = "ssh-nat"
#     source_addresses = [
#       "*"
#     ]

#     destination_ports = [
#       "22"
#     ]

#     destination_addresses = [
#       azurerm_public_ip.pip_azfw.ip_address
#     ]

#     translated_port    = 22
#     translated_address = module.control.network_interfaces.network_interface_1.private_ip_address
#     protocols = [
#       "TCP"
#     ]
#   }

#   depends_on = [
#     module.dc01,
#     module.control
#   ]
# }

resource "azurerm_firewall_network_rule_collection" "network_rule_collection_outboud_all" {
  name                = module.naming.firewall_network_rule_collection.name
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "OutBoundAllAll"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "*"
    ]

    protocols = [
      "Any"
    ]
  }
}
