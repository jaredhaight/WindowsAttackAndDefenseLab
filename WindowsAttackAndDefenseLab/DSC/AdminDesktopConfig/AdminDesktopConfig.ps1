configuration AdminDesktopConfig 
{ 
  Node "admindesktop" {
    Script DownloadFiles {
      SetScript  = { 
        $file = "https://waadtraining.blob.core.windows.net/files/admindesktop.zip"
        Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadFiles] Downloading $file"
        Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\AdminDesktop.zip
      }
      GetScript  = { @{} }
      TestScript = { 
        Test-Path C:\Windows\Temp\AdminDesktop.zip
      }
    }
    Archive UnzipFiles {
      Ensure      = "Present"
      Destination = "C:\DSCFILES"
      Path        = "C:\Windows\Temp\AdminDesktop.zip"
      Force       = $true
      DependsOn   = "[Script]DownloadFiles"
    }
    Registry AutoUserName {
      Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
      ValueName = "DefaultUserName"
      ValueType = "String"
      ValueData = "TonyStark"
    }
    Registry AutoUserPass {
      Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
      ValueName = "DefaultPassword"
      ValueType = "String"
      ValueData = "Summer2017!"
    }
    Registry AutoUserLogon {
      Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
      ValueName = "AutoAdminLogon"
      ValueType = "String"
      ValueData = "1"
    }
    Registry AutoRDP {
      Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Run\"
      ValueName = "RemoteDesktop"
      ValueType = "String"
      ValueData = "C:\DSCFILES\RDPToTerminalServer.bat"      
      DependsOn = "[Archive]UnzipFiles"
    }
    File HideDSCFILES {
      DestinationPath = "C:\DSFILES"
      Type            = "Directory"
      Attributes      = "Hidden"
      DependsOn       = "[Archive]UnzipFiles"
    }  
  } 
}