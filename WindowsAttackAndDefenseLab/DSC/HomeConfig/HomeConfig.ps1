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
  Import-DscResource -ModuleName PSDesiredStateConfiguration, cChoco

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
    WindowsFeature NetFramework35
    {
        Ensure = "Present" 
        Name = "NET-Framework-Core"
        Source = "C:\Windows\WinSxS"
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
            $Shortcut.TargetPath = "C:\Class\Applications\ExercisePicker\ExercisePicker.exe"
            $Shortcut.WorkingDirectory = "C:\Class\Applications\ExercisePicker\"
            $Shortcut.Save()
        }
        GetScript = { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipClassFiles"
    }
    Script CreateCobaltStrikeShortcut
    {
        SetScript = {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateCobaltStrikeShortcut] Creating Shortcut"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Cobalt Strike.lnk")
            $Shortcut.TargetPath = "C:\Class\Applications\cobaltstrike\cobaltstrike.exe"
            $Shortcut.WorkingDirectory = "C:\Class\Applications\cobaltstrike\"
            $Shortcut.Save()
        }
        GetScript = { @{} }
        TestScript = { $false }
        DependsOn = "[Archive]UnzipClassFiles"
    }
    
    Script CreateBloodhoundShortcut
    {
        SetScript = {
            Add-Content -Path "C:\Windows\Temp\jah-dsc-log.txt" -Value "[CreateBloodhoundShortcut] Creating Shortcut"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Bloodhound.lnk")
            $Shortcut.TargetPath = "C:\Class\Applications\BloodHound-win32-x64\BloodHound.exe"
            $Shortcut.WorkingDirectory = "C:\Class\Applications\BloodHound-win32-x64\"
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
    cChocoInstaller installChoco
    {
      InstallDir = "c:\choco"
    }
    cChocoPackageInstaller installChrome
    {
      Name        = "googlechrome"
      DependsOn   = "[cChocoInstaller]installChoco"
      #This will automatically try to upgrade if available, only if a version is not explicitly specified.
      AutoUpgrade = $True
    }
    cChocoPackageInstaller installJre
    {
        Name        = "jre8"
        DependsOn   = "[cChocoInstaller]installChoco"
        #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        AutoUpgrade = $True
    }
    cChocoPackageInstaller installVsCode
    {
        Name        = "vscode"
        DependsOn   = "[cChocoInstaller]installChoco"
        #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        AutoUpgrade = $True
    }
    cChocoPackageInstaller installSysinternals
    {
        Name        = "sysinternals"
        DependsOn   = "[cChocoInstaller]installChoco"
        #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        AutoUpgrade = $True
    }
    cChocoPackageInstaller neo4j-community
    {
        Name        = "neo4j-community"
        DependsOn   = "[cChocoPackageInstaller]installJre"
        #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        AutoUpgrade = $True
    }
    script installNeo4jService
    {
        SetScript =  { 
            cmd.exe /c "C:\tools\neo4j-community\neo4j-community-3.5.1\bin\neo4j.bat start"
        }
        GetScript =  { @{} }
        TestScript = { $false }
        DependsOn = "[cChocoPackageInstaller]neo4j-community"
    }
    LocalConfigurationManager 
    {
        ConfigurationMode = 'ApplyOnly'
        RebootNodeIfNeeded = $true
    }
  }
}