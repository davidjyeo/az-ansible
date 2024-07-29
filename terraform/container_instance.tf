module "avm-res-containerregistry-registry" {
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.naming.container_registry.name
}

module "avm-res-containerinstance-containergroup" {
  source              = "Azure/avm-res-containerinstance-containergroup/azurerm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.naming.container_group.name
  os_type             = "linux"
  restart_policy      = "Always"
  enable_telemetry    = var.enable_telemetry
}
