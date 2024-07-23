resource "tls_private_key" "ssh" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P224"
}

resource "azurerm_key_vault_secret" "admin_ssh_key" {
  key_vault_id = module.avm-res-keyvault-vault.resource_id
  name         = "azureuser-ssh-private-key"
  value        = tls_private_key.ssh.private_key_pem

  depends_on = [
    module.avm-res-keyvault-vault
  ]
}
