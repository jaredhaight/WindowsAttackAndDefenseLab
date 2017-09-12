configuration AdminDesktopConfig 
{ 
  Import-DscResource -ModuleName PSDesiredStateConfiguration,xTimeZone

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