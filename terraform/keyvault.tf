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
  purge_protection_enabled        = true
  sku_name                        = "standard"
  public_network_access_enabled   = true

  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
    # ip_rules = [
    #   jsondecode(data.http.my_ip.response_body).ip
    # ]
  }

  secrets = {
    ssh-private-key = {
      name = "ssh-private-key"
    }
  }

  secrets_value = {
    ssh-private-key = tls_private_key.ssh.private_key_pem
  }

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
}
