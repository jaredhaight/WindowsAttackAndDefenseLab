configuration TerminalServerConfig
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
  
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
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}