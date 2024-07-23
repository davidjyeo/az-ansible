# resource "azapi_resource_action" "ssh_public_key_gen" {
#   type                   = "Microsoft.Compute/sshPublicKeys@2023-09-01"
#   resource_id            = azapi_resource.ssh_public_key.id
#   action                 = "generateKeyPair"
#   method                 = "POST"
#   response_export_values = ["publicKey", "privateKey"]
# }

# resource "azapi_resource" "ssh_public_key" {
#   type      = "Microsoft.Compute/sshPublicKeys@2023-09-01"
#   name      = "linux-ssh-public-key"
#   location  = azurerm_resource_group.rg.location
#   parent_id = azurerm_resource_group.rg.id
# }

resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P224"
  # rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "admin_ssh_key" {
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = "azureuser-ssh-private-key"
  value        = tls_private_key.this.private_key_pem

  depends_on = [
    module.avm_res_keyvault_vault
  ]
}
