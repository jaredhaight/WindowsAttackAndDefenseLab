configuration TerminalServerConfig
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $filesUrl"
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  
  Node localhost 
  {
    WindowsFeature FileServer
    {
        Ensure = "Present" 
        Name = "FS-FileServer"
    }
    WindowsFeature WebServer
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
    }
    Group AddRDPAccessGroup
    {
        GroupName='Remote Desktop Users'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\Domain Users"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
    }
    Group AddHelpDesktoAdmins
    {
        GroupName='Administrators'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\Helpdesk Users"
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