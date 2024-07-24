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

resource "azurerm_automation_dsc_nodeconfiguration" "example" {
  name                    = "test.localhost"
  resource_group_name     = azurerm_resource_group.example.name
  automation_account_name = azurerm_automation_account.example.name
  depends_on              = [azurerm_automation_dsc_configuration.example]

  content_embedded = <<mofcontent
instance of MSFT_FileDirectoryConfiguration as $MSFT_FileDirectoryConfiguration1ref
{
  ResourceID = "[File]bla";
  Ensure = "Present";
  Contents = "bogus Content";
  DestinationPath = "c:\\bogus.txt";
  ModuleName = "PSDesiredStateConfiguration";
  SourceInfo = "::3::9::file";
  ModuleVersion = "1.0";
  ConfigurationName = "bla";
};
instance of OMI_ConfigurationDocument
{
  Version="2.0.0";
  MinimumCompatibleVersion = "1.0.0";
  CompatibleVersionAdditionalProperties= {"Omi_BaseResource:ConfigurationName"};
  Author="bogusAuthor";
  GenerationDate="06/15/2018 14:06:24";
  GenerationHost="bogusComputer";
  Name="test";
};
mofcontent

}
