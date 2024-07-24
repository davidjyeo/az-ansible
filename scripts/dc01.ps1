Configuration dc01
{
  $domainCred = Get-AutomationPSCredential -Name "localmgr"
  $domainName = Get-AutomationVariable -Name "ansible-poc"
  $domainDN = Get-AutomationVariable -Name "DC=ansible-poc,DC=local"
	
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSCredential]
    $SafeModePassword
  )
  
  
  
  # Import the modules needed to run the DSC script
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DScResource -ModuleName ComputerManagementDsc
  Import-DscResource -ModuleName ActiveDirectoryDsc

  Node localhost

  {
    WindowsFeature ADDS {
      Ensure = "Present"
      Name   = "AD-Domain-Services"
    }

    WindowsFeature RSAT {
      Ensure = "Present"
      Name   = "RSAT-ADDS"
    }

    WindowsFeature InstallRSAT-AD-PowerShell {
      Ensure = "Present"
      Name   = "RSAT-AD-PowerShell"
    }
		
    ADDomain $domainName {
      DomainName                    = $domainName
      Credential                    = $domainCred
      SafemodeAdministratorPassword = $domainCred
      ForestMode                    = 'WinThreshold'
      DependsOn                     = "[WindowsFeature]ADDSInstall"
    }	

    WaitForADDomain $domainName {
      DomainName           = $domainName
      WaitTimeout          = 600
      RestartCount         = 2
      PsDscRunAsCredential = $domainCred
    }

    # ADOrganizationalUnit 'Demo' {
    #   Name                            = "Demo"
    #   Path                            = "$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "TopLevel OU"
    #   Ensure                          = 'Present'
    # }
		
    # ADOrganizationalUnit 'WebServers' {
    #   Name                            = "WebServers"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "WebServers OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }

    # ADOrganizationalUnit 'Administration' {
    #   Name                            = "Administration"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "Administration OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }

    # ADOrganizationalUnit 'AdminUsers' {
    #   Name                            = "AdminUsers"
    #   Path                            = "OU=Administration,OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "Administration OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Administration"
    # }

    # ADOrganizationalUnit 'ServiceAccounts' {
    #   Name                            = "ServiceAccounts"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "ServiceAccounts OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }

    # ADOrganizationalUnit 'Citrix' {
    #   Name                            = "Citrix"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "Citrix OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }		
    
    # ADOrganizationalUnit 'Users' {
    #   Name                            = "Users"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "Users OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }
    
    # ADOrganizationalUnit 'Servers' {
    #   Name                            = "Servers"
    #   Path                            = "OU=Demo,$domainDN"
    #   ProtectedFromAccidentalDeletion = $true
    #   Description                     = "Servers OU"
    #   Ensure                          = 'Present'
    #   DependsOn                       = "[ADOrganizationalUnit]Demo"
    # }
  }
}
