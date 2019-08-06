configuration TerminalServerConfig
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        [Parameter(Mandatory)]
        [String]$waadFolderUrl
    )
  
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node localhost 
  {

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

    File NETSourceFolder {
        Type = "directory"
        DestinationPath = "C:\NETSource"
        Ensure = "Present"
    }

    Script DotNet351CabDownload {
        SetScript = {            
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadWAADFiles] Downloading .NET cab"
            Invoke-WebRequest -Uri "http://www.waad.training/microsoft-windows-netfx3-ondemand-package.cab" -OutFile "C:\NETSource\microsoft-windows-netfx3-ondemand-package.cab"
        }
        GetScript =  { @{} }
        TestScript = {
            Test-Path "C:\NETSource\microsoft-windows-netfx3-ondemand-package.cab"
        }
        DependsOn = "[File]NETSourceFolder"
    }

    WindowsFeature RemoteDesktop
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
    }

    WindowsFeature DotNetCore
    {
        Ensure = "Present" 
        Name = "Net-Framework-Core"
        Source = "C:\NETSource"
        DependsOn = "[Script]DotNet351CabDownload"
    }
    
    Script SetTimeZone
    {
        SetScript =  { 
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[SetTimeZone] Running.."
            cmd.exe /c 'tzutil /s "Eastern Standard Time"'
        }
        GetScript =  { @{} }
        TestScript = { $false }
    }

    Group AddRDPAccessGroup
    {
        GroupName='Remote Desktop Users'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\Domain Users"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
    }
    
    Group AddAdmins
    {
        GroupName='Administrators'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\HelpDeskUsers", "$DomainName\ServiceAccounts"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
    }
    
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}