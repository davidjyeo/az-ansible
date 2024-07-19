terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    # tls = {
    #   source = "hashicorp/tls"
    # }
    # local = {
    #   source = "hashicorp/local"
    # }
    # random = {
    #   source = "hashicorp/random"
    # }
    # http = {
    #   source = "hashicorp/http"
    # }
    # time = {
    #   source = "hashicorp/time"
    # }
    azapi = {
      source = "azure/azapi"
    }
    template = {
      source = "hashicorp/template"
    }
    # azuread = {
    #   source = "hashicorp/azuread"
    # }
  }

  backend "azurerm" {
    resource_group_name  = "uks-poc-tfrm-01-rg"
    storage_account_name = "ukspoctfrm01strgacc"
    container_name       = "tfstate"
    key                  = "ansible.terraform.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = true
    }
  }
  use_oidc            = true
  storage_use_azuread = true
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

provider "azuread" {
  use_oidc  = true # or use the environment variable "ARM_USE_OIDC=true"
  tenant_id = data.azurerm_subscription.current.tenant_id
  # features {}
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
