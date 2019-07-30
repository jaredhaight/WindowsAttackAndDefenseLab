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
    WindowsFeature RemoteDesktop
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
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
    WindowsFeature DotNetCore
    {
        Ensure = "Present" 
        Name = "Net-Framework-Core"
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