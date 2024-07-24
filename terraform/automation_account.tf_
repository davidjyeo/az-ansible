resource "azurerm_automation_account" "aa" {
  name                = module.naming.automation_account.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.uai.id
    ]
  }
}

resource "azurerm_automation_credential" "cred" {
  name                    = "localmgr"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  username                = "localmgr"
  password                = "1QAZ2wsx3edc"
  description             = "This is an example credential for the domain setup"
}


# ActiveDirectoryDsc
resource "azurerm_automation_module" "addsc" {
  name                    = "ActiveDirectoryDsc"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/activedirectorydsc.6.5.0.nupkg"
  }
}

resource "azurerm_automation_powershell72_module" "addsc" {
  name                  = "ActiveDirectoryDsc"
  automation_account_id = azurerm_automation_account.aa.id

  module_link {
    uri = "https://psg-prod-eastus.azureedge.net/packages/activedirectorydsc.6.5.0.nupkg"
  }
}

resource "azurerm_automation_dsc_configuration" "domain" {
  name                    = "dc01"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  location                = azurerm_resource_group.rg.location
  content_embedded        = file("../scripts/dc01.ps1")
}
