Configuration DC1
{
  $domainCred = Get-AutomationPSCredential -Name "DomainAdmin"
  $domainName = Get-AutomationVariable -Name "ansible"
  $domainDN = Get-AutomationVariable -Name "DomainDN"
	
  # Import the modules needed to run the DSC script
  Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
  Import-DScResource -ModuleName 'ComputerManagementDsc'
  Import-DscResource -ModuleName 'ActiveDirectoryDsc'	

  Node "Localhost"
  {
    WindowsFeature ADDSInstall {
      Ensure    = "Present"
      Name      = "AD-Domain-Services"
      DependsOn = "[Computer]NewComputerName"
    }

    WindowsFeature ADDSTools {
      Ensure = "Present"
      Name   = "RSAT-ADDS"
    }

    WindowsFeature InstallRSAT-AD-PowerShell {
      Ensure = "Present"
      Name   = "RSAT-AD-PowerShell"
    }
		
    ADDomain $DomainName {
      DomainName                    = $DomainName
      Credential                    = $domainCred
      SafemodeAdministratorPassword = $domainCred
      ForestMode                    = 'WinThreshold'
      DependsOn                     = "[WindowsFeature]ADDSInstall"
    }	

    WaitForADDomain $DomainName {
      DomainName           = $DomainName
      WaitTimeout          = 600
      RestartCount         = 2
      PsDscRunAsCredential = $domainCred
    }

    ADOrganizationalUnit 'Demo' {
      Name                            = "Demo"
      Path                            = "$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "TopLevel OU"
      Ensure                          = 'Present'
    }
		
    ADOrganizationalUnit 'WebServers' {
      Name                            = "WebServers"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "WebServers OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }

    ADOrganizationalUnit 'Administration' {
      Name                            = "Administration"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "Administration OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }

    ADOrganizationalUnit 'AdminUsers' {
      Name                            = "AdminUsers"
      Path                            = "OU=Administration,OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "Administration OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Administration"
    }

    ADOrganizationalUnit 'ServiceAccounts' {
      Name                            = "ServiceAccounts"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "ServiceAccounts OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }

    ADOrganizationalUnit 'Citrix' {
      Name                            = "Citrix"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "Citrix OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }		
    
    ADOrganizationalUnit 'Users' {
      Name                            = "Users"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "Users OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }
    
    ADOrganizationalUnit 'Servers' {
      Name                            = "Servers"
      Path                            = "OU=Demo,$domainDN"
      ProtectedFromAccidentalDeletion = $true
      Description                     = "Servers OU"
      Ensure                          = 'Present'
      DependsOn                       = "[ADOrganizationalUnit]Demo"
    }		
    
    # ADUser	 'svc_sql' {
    #   UserName              = 'svc_sql'
    #   Description           = "Service account for SQL"
    #   Credential            = $Cred
    #   PasswordNotRequired   = $true
    #   DomainName            = 'MTH-Consulting.dk'
    #   Path                  = "OU=ServiceAccounts,OU=Demo,$domainDN"
    #   Ensure                = 'Present'
    #   DependsOn             = "[ADOrganizationalUnit]ServiceAccounts"
    #   Enabled               = $true
    #   UserPrincipalName     = "svc_sql@MTH-Consulting.dk"
    #   PasswordNeverExpires  = $true
    #   ChangePasswordAtLogon = $false
    # }
  }
}
