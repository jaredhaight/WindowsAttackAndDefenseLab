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
    [String]$userDesktopClassFolderUrl,
    [Parameter(Mandatory)]
    [String]$waadFolderUrl
  )
  
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node localhost 
  {
    Script DownloadClassFiles {
      SetScript  = { 
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading UserDesktop.zip"
        Invoke-WebRequest -Uri $using:userDesktopClassFolderUrl -OutFile C:\Windows\Temp\Class.zip
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
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadWAADFiles] Downloading WAAD.zip"
        Invoke-WebRequest -Uri $using:waadFolderUrl -OutFile C:\Windows\Temp\WAAD.zip
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
      MembersToInclude     = "$DomainName\HelpDeskUsers", "$DomainName\Accounting Users", "$DomainName\ServiceAccounts", "$DomainName\WorkstationAdmins"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    
    LocalConfigurationManager {
      ConfigurationMode  = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  }
}