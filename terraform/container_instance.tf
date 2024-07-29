resource "azurerm_container_registry" "acr" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = replace("${module.naming.container_registry.name}", "/-/", "")
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
  # georeplications {
  #   location                = "East US"
  #   zone_redundancy_enabled = true
  #   tags                    = {}
  # }
  # georeplications {
  #   location                = "North Europe"
  #   zone_redundancy_enabled = true
  #   tags                    = {}
  # }
}

# module "avm-res-containerregistry-registry" {
#   source              = "Azure/avm-res-containerregistry-registry/azurerm"
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = replace("${module.naming.container_registry.name}", "/-/", "")
#   georeplications = 
# }

#acrans-adv-uks-01

resource "azurerm_container_group" "aci" {
  name                = module.naming.container_group.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.container_subnet.id]

  container {
    name   = "hello-world"
    image  = "ubuntu:latest"
    cpu    = "1.0"
    memory = "2.0"

    ports {
      port     = 22
      protocol = "TCP"
    }
  }
}

# module "avm-res-containerinstance-containergroup" {
#   source              = "Azure/avm-res-containerinstance-containergroup/azurerm"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = module.naming.container_group.name
#   # name                = replace("${module.naming.container_group.name}", "/-/", "")
#   os_type          = "Linux"
#   restart_policy   = "Always"
#   enable_telemetry = var.enable_telemetry

#   subnet_ids = [azurerm_subnet.container_subnet.id]

#   containers = {
#     container1 = {
#       name   = "helloworld"
#       image  = "mcr.microsoft.com/hello-world" #:latest"
#       cpu    = "1"
#       memory = "2"
#       ports = [
#         {
#           port     = 22
#           protocol = "TCP"
#         }
#       ]
#       # environment_variables = {
#       #   "ENVIRONMENT" = "production"
#       # }
#       # secure_environment_variables = {
#       #   "SECENV" = "avmpoc"
#       # }
#       volumes = {
#         secrets = {
#           mount_path = "/etc/secrets"
#           name       = "secret1"
#           # secret = {
#           #   "password" = base64encode("password123")
#           # }
#         }
#         #   nginx = {
#         #     mount_path = "/usr/share/nginx/html"
#         #     name       = "nginx"
#         #     secret = {
#         #       "indexpage" = base64encode("Hello, World!")
#         #     }
#         #   }
#       }
#     }
#   }
# }
