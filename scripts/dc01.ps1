Configuration dc01
{
  # Retrieve automation variables and credentials
  $domainCred = Get-AutomationPSCredential -Name "localmgr"
  $domainName = Get-AutomationVariable -Name "DomainName" # Adjust to match your Azure Automation variable name
  $domainDN = Get-AutomationVariable -Name "DomainDN"     # Adjust to match your Azure Automation variable name

  # Import the modules needed to run the DSC script
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName ComputerManagementDsc
  Import-DscResource -ModuleName ActiveDirectoryDsc

  Node 'localhost'
  {
    # Ensure AD DS is installed
    WindowsFeature ADDS {
      Ensure = "Present"
      Name   = "AD-Domain-Services"
    }

    # Ensure RSAT tools are installed
    WindowsFeature RSAT {
      Ensure = "Present"
      Name   = "RSAT-AD-AdminCenter"
    }

    # Ensure AD PowerShell module is installed
    WindowsFeature InstallRSAT_AD_PowerShell {
      Ensure = "Present"
      Name   = "RSAT-AD-PowerShell"
    }

    # Create and configure the Active Directory Domain
    ADDomain 'CreateDomain' {
      DomainName                    = $domainName
      Credential                    = $domainCred
      SafemodeAdministratorPassword = $SafeModePassword
      ForestMode                    = 'WinThreshold'
      DatabasePath                  = 'C:\NTDS'
      LogPath                       = 'C:\NTDS'
      SysvolPath                    = 'C:\SYSVOL'
      DependsOn                     = "[WindowsFeature]ADDS"
    }

    # Wait for AD domain to be fully created
    WaitForADDomain 'WaitForDomain' {
      DomainName           = $domainName
      WaitTimeout          = 600
      RetryIntervalSec     = 60
      PsDscRunAsCredential = $domainCred
      DependsOn            = "[ADDomain]CreateDomain"
    }
  }
}

