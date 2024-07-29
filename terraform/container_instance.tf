module "avm-res-containerregistry-registry" {
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  name                = replace("${module.naming.container_registry.name}", "/-/", "")
}

#acrans-adv-uks-01

module "avm-res-containerinstance-containergroup" {
  source              = "Azure/avm-res-containerinstance-containergroup/azurerm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.naming.container_group.name
  # name                = replace("${module.naming.container_group.name}", "/-/", "")
  os_type          = "Linux"
  restart_policy   = "Always"
  enable_telemetry = var.enable_telemetry

  subnet_ids = [azurerm_subnet.container_subnet.id]

  containers = {
    container1 = {
      name   = "control"
      image  = "ubuntu" #:latest"
      cpu    = "1"
      memory = "2"
      ports = [
        {
          port     = 22
          protocol = "TCP"
        }
      ]
      # environment_variables = {
      #   "ENVIRONMENT" = "production"
      # }
      # secure_environment_variables = {
      #   "SECENV" = "avmpoc"
      # }
      volumes = {
        secrets = {
          mount_path = "/etc/secrets"
          name       = "secret1"
          secret = {
            "password" = base64encode("password123")
          }
        }
        #   nginx = {
        #     mount_path = "/usr/share/nginx/html"
        #     name       = "nginx"
        #     secret = {
        #       "indexpage" = base64encode("Hello, World!")
        #     }
        #   }
      }
    }
  }
}
