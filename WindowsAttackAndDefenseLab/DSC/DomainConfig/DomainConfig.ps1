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
  [string]$filesUrl,

  [Parameter(Mandatory)]
  [string]$linuxNicIpAddress,

  [Int]$RetryCount=20,
  [Int]$RetryIntervalSec=30
  ) 

  Import-DscResource -ModuleName xActiveDirectory, xDisk, xNetworking, cDisk,xDnsServer, PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential]$DomainAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  [System.Management.Automation.PSCredential]$DomainStudentCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($StudentCreds.UserName)", $StudentCreds.Password)
  [System.Management.Automation.PSCredential]$DomainBackupUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($BackupUserCreds.UserName)", $BackupUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainHelpDeskUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($HelpDeskUserCreds.UserName)", $HelpDeskUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainAccountingUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($AccountingUserCreds.UserName)", $AccountingUserCreds.Password)
  [System.Management.Automation.PSCredential]$DomainServerAdminCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($ServerAdminCreds.UserName)", $ServerAdminCreds.Password)

  $AdminUserName = $Admincreds.UserName
  $StudentUserName = $StudentCreds.UserName
  $BackupUserUsername = $BackupUserCreds.UserName
  $HelpDeskUserUsername = $HelpDeskUserCreds.UserName
  $AccountingUserUsername = $AccountingUserCreds.UserName
  $ServerAdminUsername = $ServerAdminCreds.UserName
  
  $Interface=Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
  $InterfaceAlias=$($Interface.Name)

  Node localhost
  {
    Script AddADDSFeature {
      SetScript = {
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[AddADDSFeature] Installing ADDS.."
        Add-WindowsFeature "AD-Domain-Services" -ErrorAction SilentlyContinue   
      }
      GetScript =  { @{} }
      TestScript = { $false }
    }
    Script DownloadBootstrapFiles
    {
        SetScript =  { 
            $file = $using:filesUrl + 'DCBootstrapFiles.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadBootstrapFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\bootstrap.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\bootstrap.zip
         }
    }
    Archive UnzipBootstrapFiles
    {
        Ensure = "Present"
        Destination = "C:\Bootstrap"
        Path = "C:\Windows\Temp\Bootstrap.zip"
        Force = $true
        DependsOn = "[Script]DownloadBootstrapFiles"
    }
    Script ImportGPOs
    {
        SetScript =  {
          Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Running.." 
          Try {
            New-GPO -Name "Class Default"
            Import-GPO -Path "C:\Bootstrap" -BackupId '{CC5B8698-C56C-4B4C-B2A2-745A551E37E7}' -TargetName "Class Default"
            New-GPLink -Name "Class Default" -Target "DC=AD,DC=WAAD,DC=TRAINING"
          }
          Catch {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Failed.."
            $exception = $error[0].Exception
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[ImportGPOs] Error: $exception"
          }
        }
        GetScript =  { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipBootstrapFiles","[xADOrganizationalUnit]ProductionServersOU"
    }
    Script CreateFillerUsers
    {
        SetScript =  {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateFillerUsers] Running.."
            $users = Import-Csv C:\Bootstrap\user_data.csv
            $userOus = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Staff,OU=Production,DC=ad,dc=waad,dc=training"

            forEach ($user in $users) {
                $username = $user.username
                $i++
                Try {
                    $first = $user.first_name
                    $last = $user.last_name
                    $fullName = "$first $last"
                    $username = $user.username
                    $password = $user.password + "ase235"
                    $title = $user.title
                        
                    Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateFillerUsers] Creating $username.."
                    $OU = Get-Random $userOUs
                    $NewUser = New-ADUser -Name $fullName -GivenName $first -Surname $last -SamAccountName $username `
                        -UserPrincipalName "$username@ad.evil.training" -AccountPassword (ConvertTo-SecureString -String $password -AsPlainText -Force) `
                        -Path $OU
                    if (!($i % 3 -eq 0)) {
                      Enable-ADAccount $NewUser
                    }
                }
                Catch {
                    Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateFillerUsers] Failed creating $username.."
                    $exception = $error[0].Exception
                    Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateFillerUsers] Error: $exception"
                }
            }

        }
        GetScript =  { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipBootstrapFiles","[xADOrganizationalUnit]ProductionStaffOU"
    }
    WindowsFeature DNS 
    { 
      Ensure = "Present" 
      Name = "DNS"		
    }
    xDnsRecord LinuxHost
    {
        Name = "linux"
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

    xWaitforDisk Disk2
    {
      DiskNumber = 2
      RetryIntervalSec =$RetryIntervalSec
      RetryCount = $RetryCount
    }

    cDiskNoRestart ADDataDisk
    {
      DiskNumber = 2
      DriveLetter = "F"
    }

    WindowsFeature ADDSInstall 
    { 
      Ensure = "Present" 
      Name = "AD-Domain-Services"
      DependsOn="[cDiskNoRestart]ADDataDisk", "[Script]AddADDSFeature"
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
    xADUser StudentUser
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainAdminCreds
        UserName = "StudentUser"
        Password = $DomainStudentCreds
        Ensure = "Present"
        Path = "OU=Users,OU=Class,DC=ad,DC=waad,DC=training"
        DependsOn = "[xADOrganizationalUnit]ClassUsersOU"
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
    xADGroup LocalAdmins
    {
      GroupName = "LocalAdmins"
      GroupScope = "Global"
      Category = "Security"
      Description = "Group for Local Admins"
      Ensure = 'Present'
      MembersToInclude = "StudentAdmin"
      Path = "OU=Groups,OU=Class,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ClassGroupsOU", "[xADUser]StudentAdmin"
    }
    xADGroup ClassRDPAccess
    {
      GroupName = "Class Remote Desktop Access"
      GroupScope = "Global"
      Category = "Security"
      Description = "Group for RDP Access to objects in the Class OU"
      Ensure = 'Present'
      MembersToInclude = "StudentUser"
      Path = "OU=Groups,OU=Class,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ClassGroupsOU", "[xADUser]StudentUser"
    }
    xADGroup DomainAdmins
    {
      GroupName = "Domain Admins"
      Ensure = 'Present'
      MembersToInclude = $BackupUserUsername, $ServerAdminUsername
      DependsOn = "[xADUser]BackupUser", "[xADUser]ServerAdmin"
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
      GroupName = "Helpdesk Users"
      GroupScope = "Global"
      Category = "Security"
      Description = "The valiant frontline of IT Support"
      Ensure = 'Present'
      MembersToInclude = $HelpDeskUserUsername
      Path = "OU=Groups,OU=Production,DC=ad,DC=waad,DC=training"
      DependsOn = "[xADOrganizationalUnit]ProductionGroupsOU", "[xADUser]HelpdeskUser"
    }
    LocalConfigurationManager 
    {
      ConfigurationMode = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
} 