configuration AdminDesktopConfig 
{ 
  Param(
    [Parameter(Mandatory)]
    [String]$DomainName,
    [Parameter(Mandatory)]
    [System.Management.Automation.PSCredential]$Admincreds,
    [Parameter(Mandatory)]
    [string]$waadFolderUrl
  )
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node "admindesktop" {

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
    Group AddToAdmins {
      GroupName            = 'Administrators'   
      Ensure               = 'Present'             
      MembersToInclude     = "$DomainName\WorkstationAdmins"
      Credential           = $DomainCreds    
      PsDscRunAsCredential = $DomainCreds
    }
    LocalConfigurationManager {
      ConfigurationMode  = 'ApplyOnly'
      RebootNodeIfNeeded = $true
    }
  } 
}