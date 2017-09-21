configuration HomeConfig 
{
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$classUrl,
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )
  
  Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[Start] Got FileURL: $classUrl"
  [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Node localhost 
  {
    WindowsFeature ADTools
    {
        Ensure = "Present" 
        Name = "RSAT-AD-Tools"
    }
    WindowsFeature ADAdminCenter
    {
        Ensure = "Present" 
        Name = "RSAT-AD-AdminCenter"
    }
    WindowsFeature ADDSTools
    {
        Ensure = "Present" 
        Name = "RSAT-ADDS-Tools"
    }
    WindowsFeature ADPowerShell
    {
        Ensure = "Present" 
        Name = "RSAT-AD-PowerShell"
    }
    WindowsFeature RSATDNS
    {
        Ensure = "Present" 
        Name = "RSAT-DNS-Server"
    }
    WindowsFeature RSATFileServices
    {
        Ensure = "Present" 
        Name = "RSAT-File-Services"
    }
    WindowsFeature GPMC
    {
        Ensure = "Present" 
        Name = "GPMC"
    }    
    WindowsFeature RemoteDesktop
    {
        Ensure = "Present" 
        Name = "RDS-RD-Server"
    }
    Script DownloadClassFiles
    {
        SetScript =  { 
            $file = $using:classUrl + 'Home.zip'
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[DownloadClassFiles] Downloading $file"
            Invoke-WebRequest -Uri $file -OutFile C:\Windows\Temp\Class.zip
        }
        GetScript =  { @{} }
        TestScript = { 
            Test-Path C:\Windows\Temp\class.zip
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
    Script CreateMSTCShortcut
    {
        SetScript = {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateMSTCShortcut] Creating Shortcut"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Remote Desktop.lnk")
            $Shortcut.TargetPath = "C:\Windows\System32\mstsc.exe"
            $Shortcut.Save()
        }
        GetScript = { @{} }
        TestScript = { $false }
    }
    Script CreatePickerShortcut
    {
        SetScript = {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreatePickerShortcut] Creating Shortcut"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Exercise Picker.lnk")
            $Shortcut.TargetPath = "C:\Class\ExercisePicker\ExercisePicker.exe"
            $Shortcut.WorkingDirectory = "C:\Class\ExercisePicker\"
            $Shortcut.Save()
        }
        GetScript = { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipClassFiles"
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
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}