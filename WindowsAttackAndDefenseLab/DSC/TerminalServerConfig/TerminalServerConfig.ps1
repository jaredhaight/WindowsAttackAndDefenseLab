configuration TerminalServerConfig
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        [Parameter(Mandatory)]
        [String]$classUrl
    )
  
  Import-DscResource -ModuleName PSDesiredStateConfiguration, xTimeZone
  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node localhost 
  {

    Script DownloadClassFiles
    {
        SetScript =  { 
            $file = $using:classUrl + 'TerminalServer.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
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
    WindowsFeature WebServer
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
    }
    Script InstallxComputerManagament
    {
        SetScript = {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Install-Module xComputerManagement -Force
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
        MembersToInclude= "$DomainName\Helpdesk Users", "$DomainName\LocalAdmins"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
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