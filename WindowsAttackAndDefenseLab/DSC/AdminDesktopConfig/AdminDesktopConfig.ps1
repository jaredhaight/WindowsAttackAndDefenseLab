configuration AdminDesktopConfig 
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
  Node "admindesktop" {
    Script DownloadFiles {
      SetScript  = { 
        $file = "https://waadtraining.blob.core.windows.net/class/AdminDesktop.zip"
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadFiles] Downloading $file"
        Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\WAAD.zip
      }
      GetScript  = { @{} }
      TestScript = { 
        Test-Path C:\Windows\Temp\DSCFILES.zip
      }
    }
    WindowsFeature DotNetCore
    {
        Ensure = "Present" 
        Name = "Net-Framework-Core"
    }
    Archive UnzipFiles {
      Ensure      = "Present"
      Destination = "C:\Class"
      Path        = "C:\Windows\Temp\WAAD.zip"
      Force       = $true
      DependsOn   = "[Script]DownloadFiles"
    }
    File HideDSCFILES {
      DestinationPath = "C:\DSFILES"
      Type            = "Directory"
      Attributes      = "Hidden"
      DependsOn       = "[Archive]UnzipFiles"
    }
    Group AddToAdmins
    {
        GroupName='Administrators'   
        Ensure= 'Present'             
        MembersToInclude= "$DomainName\Helpdesk Users", "$DomainName\Accounting Users", "$DomainName\LocalAdmins"
        Credential = $DomainCreds    
        PsDscRunAsCredential = $DomainCreds
    }  
  } 
}