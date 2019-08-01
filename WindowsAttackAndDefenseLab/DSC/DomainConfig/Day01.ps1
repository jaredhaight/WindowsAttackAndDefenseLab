configuration DomainConfig 
{ 
  param 
  ( 
  [Parameter(Mandatory)]
  [String]$DomainName,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$Admincreds,
  
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$StudentCreds,
    
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$BackupUserCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$HelpDeskUserCreds,

  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$AccountingUserCreds,

    [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$ServerAdminCreds,
  
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$HelperAccountCreds,
  
  [Parameter(Mandatory)]
  [System.Management.Automation.PSCredential]$SQLAccountCreds,

  [Parameter(Mandatory)]
  [string]$dcClassFolderUrl,

  [Parameter(Mandatory)]
  [string]$waadFolderUrl,

  [Parameter(Mandatory)]
  [string]$linuxNicIpAddress,

  [Int]$RetryCount=20,
  [Int]$RetryIntervalSec=30
  ) 

  Import-DscResource -ModuleName xActiveDirectory, xDisk, xNetworking, cDisk,xDnsServer, PSDesiredStateConfiguration, xTimeZone
  [System.Management.Automation.PSCredential]$DomainAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  [System.Management.Automation.PSCredential]$DomainStudentCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($StudentCreds.UserName)", $StudentCreds.Password)
  [System.Management.Automation.PSCredential]$DomainBackupUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($BackupUserCreds.UserName)", $BackupUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainHelpDeskUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($HelpDeskUserCreds.UserName)", $HelpDeskUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainAccountingUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($AccountingUserCreds.UserName)", $AccountingUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainServerAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($ServerAdminCreds.UserName)", $ServerAdminCreds.Password)
  [System.Management.Automation.PSCredential]$DomainHelperAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($HelperAccountCreds.UserName)", $HelperAccountCreds.Password)
  [System.Management.Automation.PSCredential]$DomainSQLAccountCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($SQLAccountCreds.UserName)", $SQLAccountCreds.Password)
  
  $AdminUserName = $Admincreds.UserName
  $BackupUserUsername = $BackupUserCreds.UserName
  $HelpDeskUserUsername = $HelpDeskUserCreds.UserName
  $AccountingUserUsername = $AccountingUserCreds.UserName
  $ServerAdminUsername = $ServerAdminCreds.UserName
  $HelperAccountUsername = $HelperAccountCreds.UserName
  $SQLAccountUsername = $SQLAccountCreds.UserName
  
  $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
  $InterfaceAlias=$($Interface.Name)

  Node localhost
  {
    Script DownloadClassFiles
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading DC.zip"
            Invoke-WebRequest -Uri $using:dcClassFolderUrl -OutFile C:\Windows\Temp\Class.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\Class.zip
         }
    }
    Archive UnzipClassFiles
    {
        Ensure = "Present"
        Destination = "C:\Class"
        Path = "C:\Windows\Temp\Class.zip"
        Force = $true
        DependsOn = "[Script]DownloadClassFiles"
    }
    Script DownloadWAADFiles
    {
        SetScript =  {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadWAADFiles] Downloading WAAD.zip"
            Invoke-WebRequest -Uri $using:waadFolderUrl -OutFile C:\Windows\Temp\WAAD.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\WAAD.zip
         }
    }
    Archive UnzipWAADFiles
    {
        Ensure = "Present"
        Destination = "C:\WAAD"
        Path = "C:\Windows\Temp\WAAD.zip"
        Force = $true
        DependsOn = "[Script]DownloadWAADFiles"
    }
    Script ImportGPOs
    {
        SetScript =  {
          Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Running.." 
          Try {
            New-GPO -Name "WAAD Default"
            New-GPO -Name "Student Computers"
            New-GPO -Name "Disable Firewall"
            New-GPO -Name "Shared Folder"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{FF68FA65-A8D6-448D-87E5-6140373380CF}' -TargetName "Disable Firewall"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{BD3497A3-0BBC-4F59-8B26-F54C6CA6FD07}' -TargetName "Shared Folder"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{AC5D004D-2C93-46AB-A1F8-2D6A64CF491F}' -TargetName "WAAD Default"
            Import-GPO -Path "C:\WAAD\GPOs" -BackupId '{9FF1FF6F-FB61-4961-A30B-77148F45B36B}'-TargetName "Student Computers"
            New-GPLink -Name "Disable Firewall" -Target "OU=Domain Controllers,DC=ad,DC=waad,DC=training"
            New-GPLink -Name "Disable Firewall" -Target "OU=Production,DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Shared Folder" -Target "OU=Production,DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "WAAD Default" -Target "DC=AD,DC=WAAD,DC=TRAINING"
            New-GPLink -Name "Student Computers" -Target "OU=Computers,OU=Class,DC=AD,DC=WAAD,DC=TRAINING"
          }
          Catch {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Failed.."
            $exception = $error[0].Exception
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Error: $exception"
          }
        }
        GetScript =  { @{} }
        TestScript = { try {Get-GPO -Name "WAAD Default2" -ErrorAction Stop | Out-null; return $true} catch { $false } }
        DependsOn = "[Archive]UnzipClassFiles","[xADOrganizationalUnit]ProductionServersOU","[xADOrganizationalUnit]ClassComputersOU"
    }
    WindowsFeature DNS 
    { 
      Ensure = "Present" 
      Name = "DNS"		
    }
    WindowsFeature DotNetCore 
    {
      Ensure = "Present" 
      Name   = "Net-Framework-Core"
    }
    xDnsRecord Pwnbox
    {
        Name = "pwnbox"
        Target = $LinuxNicIpAddress
        Zone = $DomainName
        Type = "ARecord"
        Ensure = "Present"
        DependsOn="[WindowsFeature]DNS"
    }

    Script DnsDiagnosticsScript
    {
      SetScript =  { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DnsDiagnosticsScript] Enabling DNS Diagnostics"
        Set-DnsServerDiagnostics -All $true
        Write-Verbose -Verbose "Enabling DNS client diagnostics" 
      }
      GetScript =  { @{} }
      TestScript = { $false }
      DependsOn = "[WindowsFeature]DNS"
    }

    WindowsFeature DnsTools
    {
      Ensure = "Present"
      Name = "RSAT-DNS-Server"
    }

    xDnsServerAddress DnsServerAddress 
    { 
      Address        = '127.0.0.1' 
      InterfaceAlias = $InterfaceAlias
      AddressFamily  = 'IPv4'
      DependsOn = "[WindowsFeature]DNS"
    }

    WindowsFeature ADDSInstall 
    { 
      Ensure = "Present" 
      Name = "AD-Domain-Services"
    } 

    xADDomain FirstDS 
    {
      DomainName = $DomainName
      DomainAdministratorCredential = $DomainAdminCreds
      SafemodeAdministratorPassword = $DomainAdminCreds
      DependsOn = "[WindowsFeature]ADDSInstall"
    } 
    xWaitForADDomain DscForestWait
    {
        DomainName = $DomainName
        DomainUserCredential = $DomainAdminCreds
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[xADDomain]FirstDS"
    }
    # xADKDSKey 'KDSRootKey'
    # {
    #   Ensure = "Present"
    #   EffectiveTime = "1/1/2019 13:00"
    #   AllowUnsafeEffectiveTime = $true
    #   DependsOn = "[xWaitForADDomain]DscForestWait"
    # }
    xADOrganizationalUnit ProductionOU
    {
      Name = "Production"
      Path = "DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xWaitForADDomain]DscForestWait"
    }
    xADOrganizationalUnit ProductionStaffOU
    {
      Name = "Staff"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionComputersOU
    {
      Name = "Computers"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionServersOU
    {
      Name = "Servers"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionGroupsOU
    {
      Name = "Groups"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ProductionServiceAccountsOU
    {
      Name = "Service Accounts"
      Path = "OU=Production,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ProductionOU"
    }
    xADOrganizationalUnit ClassOU
    {
      Name = "Class"
      Path = "DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xWaitForADDomain]DscForestWait"
    }
    xADOrganizationalUnit ClassUsersOU
    {
      Name = "Users"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ClassComputersOU
    {
      Name = "Computers"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADOrganizationalUnit ClassGroupsOU
    {
      Name = "Groups"
      Path = "OU=Class,DC=ad,DC=waad,DC=training"
      Ensure = 'Present'
      DependsOn = "[xADOrganizationalUnit]ClassOU"
    }
    xADUser StudentAdmin
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentAdmin"
        Password = $DomainStudentCreds
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ClassUsersOU"
    }
    xADUser HelpdeskUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $HelpDeskUserUsername
        Password = $DomainHelpDeskUserCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }
    xADUser AccountingUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $AccountingUserUsername
        Password = $DomainAccountingUserCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }
    xADUser ServerAdmin
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $ServerAdminUsername
        Password = $DomainServerAdminCreds
        Ensure = "Present"
        Path = "OU=Staff,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionStaffOU"
    }  
    xADUser BackupUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $BackupUserUsername
        Password = $DomainBackupUserCreds
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU"
    }
    xADUser HelperAccount
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $HelperAccountUsername
        Password = $DomainHelperAccountCreds
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU"
    }
    xADUser SQLServiceAccount
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = $SQLAccountUsername
        Password = $DomainSQLAccountCreds
        ServicePrincipalNames = "MSSQLSvc/sql01.$($DomainName)","MSSQLSvc/sql01.$($DomainName):1433"
        Ensure = "Present"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU"
    }
    xADManagedServiceAccount gMSAServiceAccount
    {
        Ensure = "Present"
        Credential = $DomainAdminCreds
        ServiceAccountName = "_SVC01"
        AccountType = "Group"
        Path = "OU=Service Accounts,OU=Production,DC=ad,DC=waad,DC=training"
        Members = "$($ServerAdminUsername)", "Computer01$"
        DependsOn = "[xADOrganizationalUnit]ProductionServiceAccountsOU", "[xADUser]ServerAdmin"
    }
    Script SetgMSAServicePrincipalNames
    {
      SetScript =  { 
        Get-ADUser -Filter {SamAccountName -eq '_SVC01'} -Credential $DomainAdminCreds | Set-ADUser -ServicePrincipalNames @{Add="MSSQLSvc/sql02.$($DomainName)", "MSSQLSvc/sql02.$($DomainName):1433"} -Credential $DomainAdminCreds
        Write-Verbose -Verbose "Enabling DNS client diagnostics" 
      }
      GetScript =  { @{} }
      TestScript = { $false }
      DependsOn = "[xADManagedServiceAccount]gMSAServiceAccount"
    }
    xADGroup DomainAdmins
    {
      GroupName = "Domain Admins"
      Ensure = 'Present'
      MembersToInclude =  $ServerAdminUsername, "StudentAdmin"
      DependsOn = "[xADUser]ServerAdmin", "[xADUser]StudentAdmin"
    }
    xADGroup SchemaAdmins
    {
      GroupName = "Schema Admins"
      Ensure = 'Present'
      MembersToInclude = "StudentAdmin"
      DependsOn = "[xADUser]StudentAdmin"
    }
    xADGroup AccountingUsers
    {
      GroupName = "Accounting Users"
      GroupScope = "Global"
      Category = "Security"
      Description = "Conjurers of Arithmetic and Paperwork"
      Ensure = 'Present'
      MembersToInclude = $AccountingUserUsername
      Path = "OU=Groups,OU=Production,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ProductionGroupsOU", "[xADUser]AccountingUser"
    }
    xADGroup HelpdeskUsers
    {
      GroupName = "HelpdeskUsers"
      GroupScope = "Global"
      Category = "Security"
      Description = "The valiant frontline of IT Support"
      Ensure = 'Present'
      MembersToInclude = $HelpDeskUserUsername
      Path = "OU=Groups,OU=Production,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ProductionGroupsOU", "[xADUser]HelpdeskUser"
    }
    xADGroup ServiceAccounts
    {
      GroupName = "ServiceAccounts"
      GroupScope = "Global"
      Category = "Security"
      Description = "Robots that do our bidding"
      Ensure = 'Present'
      MembersToInclude = $BackupUserUsername, $HelperAccountUsername, $SQLAccountUsername
      Path = "OU=Groups,OU=Class,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ClassGroupsOU", "[xADUser]BackupUser", "[xADUser]SQLServiceAccount"
    }
    xTimeZone SetTimezone
    {
        IsSingleInstance = 'Yes'
        TimeZone         = 'Pacific Standard Time'
    }
    LocalConfigurationManager 
    {
      ConfigurationMode = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
} 