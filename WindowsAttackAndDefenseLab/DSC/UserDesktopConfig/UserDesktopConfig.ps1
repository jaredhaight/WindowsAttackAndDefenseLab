configuration UserDesktopConfig 
{
  param 
  ( 
    [Parameter(Mandatory)]
    [String]$DomainName,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Admincreds,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$BackupUserCreds,
    [Parameter(Mandatory)]
    [String]$classUrl
  )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $classUrl"
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  [System.Management.Automation.PSCredential]$DomainBackupUserCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($BackupUserCreds.UserName)", $BackupUserCreds.Password)

  Node localhost 
  {
    Script DownloadClassFiles {
      SetScript  = { 
        $file = $using:classUrl + 'UserDesktop.zip'
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
        Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
      }
      GetScript  = { @{} }
      TestScript = { 
        Test-Path C:\Windows\Temp\Class.zip
      }
    }
    Archive UnzipClassFiles {
      Ensure      = "Present"
      Destination = "C:\Class"
      Path        = "C:\Windows\Temp\Class.zip"
      Force       = $true
      DependsOn   = "[Script]DownloadClassFiles"
    }
    Script DownloadWAADFiles {
      SetScript  = { 
        $file = $using:classUrl + 'WAAD.zip'
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadWAADFiles] Downloading $file"
        Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\WAAD.zip
      }
      GetScript  = { @{} }
      TestScript = { 
        Test-Path C:\Windows\Temp\WAAD.zip
      }
    }
    Archive UnzipWAADFiles {
      Ensure      = "Present"
      Destination = "C:\WAAD"
      Path        = "C:\Windows\Temp\WAAD.zip"
      Force       = $true
      DependsOn   = "[Script]DownloadWAADFiles"
    }
    File HideWAAD {
      Type            = "Directory"
      Attributes      = 'Hidden'
      DestinationPath = "C:\WAAD"
      DependsOn       = "[Archive]UnzipWAADFiles"
    }
    Script SetTimeZone {
      SetScript  = { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[SetTimeZone] Running.."
        cmd.exe /c 'tzutil /s "Eastern Standard Time"'
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }
    WindowsFeature DotNetCore {
      Ensure = "Present" 
      Name   = "Net-Framework-Core"
    }
    WindowsFeature RemoteDesktop
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
    }
    Script InstallxComputerManagament {
      SetScript  = {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module xComputerManagement -Force
      }
      GetScript  = { @{} }
      TestScript = { $false }
    }
    Group AddRDPAccessGroup {
      GroupName            = 'Remote Desktop Users'   
      Ensure               = 'Present'             
      MembersToInclude     = "$DomainName\Domain Users"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    Group AddToAdmins {
      GroupName            = 'Administrators'   
      Ensure               = 'Present'             
      MembersToInclude     = "$DomainName\HelpDeskUsers", "$DomainName\Accounting Users", "$DomainName\ServiceAccounts"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    LocalConfigurationManager {
      ConfigurationMode  = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
}