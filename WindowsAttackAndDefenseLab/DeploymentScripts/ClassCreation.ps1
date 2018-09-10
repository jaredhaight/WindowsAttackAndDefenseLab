workflow New-WaadClass {
  [CmdletBinding()]
  Param( 
    [Parameter(Mandatory = $True, Position = 1)]
    [pscredential]$Credential,

    [Parameter(Mandatory = $True, Position = 2)]
    [string]$CsvSource,

    [string]$Day = "One"
  ) 

  $studentData = Import-CSV $csvSource
  foreach -parallel -throttle 30 ($student in $studentData) {
    $studentPassword = $student.password
    $studentCode = $student.code.toString()
    $studentNumber = $student.id
    $region = 'eastus2'
     
    if ($studentNumber % 2 -eq 0) {
      $region = 'westus2'
    }
    Write-Output "$studentNumber | $studentCode | $studentPassword | $region"
    Invoke-CreateWindowsAttackAndDefenseLab -credentials $credential -studentCode $studentCode -studentPassword $studentPassword -region $region -place $studentNumber -total $studentData.count -Day $day
  }
}

function Invoke-CreateWindowsAttackAndDefenseLab {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory = $True)]
    [string]$StudentCode,
    
    [Parameter(Mandatory = $True)]
    [string]$StudentPassword,
    [string]$Region = "eastus2",
    [int]$place = 1,
    [int]$total = 1,
    [switch]$Test,
    [string]$Day = "One"
  )

  # Import Azure Service Management module
  Import-Module AzureRM

  Write-Progress -Activity "Deploying." -Status "Deploying.." -CurrentOperation "[$place/$total] Deployment for $studentCode running.."

  # Check if logged in to Azure
  Try {
    Get-AzureRMContext -ErrorAction Stop
  }
  Catch {
    Add-AzureRmAccount -Credential $credentials
  }
  
  # Common Variables
  $location = $region
  $masterResourceGroup = "waad.training-master"
  $dnsZone = "waad.training"
  $resourceGroupName = $studentCode + '.' + $dnsZone
  $studentSubnetName = $studentCode + "subnet"
  $virtualNetworkName = $studentCode + "vnet"
  $virtualNetworkAddressRange = "10.0.0.0/16"
  $localAdminUsername = "localadmin"
  $studentAdminUsername = "studentadmin"
  $storageAccountName = $studentCode + "storage"    # Lowercase required
  $TemplateFile = "$PSScriptRoot\..\azuredeploy.json"
  $TemplateParameterFile = "$PSScriptRoot\..\azuredeploy.parameters.json"
  $networkSecurityGroup = "waad.training-nsg-" + $region
  $subscriptionId = (Get-AzureRmContext).Subscription.SubscriptionId
  $windowsImagePublisher = "MicrosoftWindowsServer"
  $windowsImageOffer = "WindowsServer"
  $windowsImageSku = "2016-Datacenter"  
  $dscUrl = "https://waadtraining.blob.core.windows.net/bootstraps/"
  $classUrl = "https://waadtraining.blob.core.windows.net/class/"
  $smallVmSize = "Standard_B2ms"
  $largeVmSize = "Standard_B4ms"

  # DC Variables
  $adAdminUserName = "WaadAdmin"
  $domainName = "ad." + $dnsZone
  $adVMName = "dc01"
  $adNicIPAddress = "10.0.0.4"
  $adVmSize = "Standard_B2ms"
  if ($Day -eq "One") {
    $adDscFile = "Day01.ps1"
  }
  elseif ($Day -eq "Two") {
    $adDscFile = "Day02.ps1"
  }
  else {
    Throw  "INVALID DAY SELECTED"
  }  
  $windows2012Sku = "2012-R2-Datacenter"

  # Home Vars
  $homeVMName = "home" # Has to be lowercase
  $homeNicIpAddress = "10.0.0.10"
  $homeVMSize = $largeVmSize
  $homeOU = "OU=Computers,OU=Class,DC=ad,DC=waad,DC=training"

  # Terminal Server Vars
  $terminalServerVMName = "terminalserver" # Has to be lowercase
  $terminalServerNicIpAddress = "10.0.0.11"
  $terminalServerVMSize = $smallVmSize
  $terminalServerOU = "OU=Servers,OU=Production,DC=ad,DC=waad,DC=training"

  # User Desktop Vars
  $userDesktopVMName = "userdesktop" # Has to be lowercase
  $userDesktopNicIpAddress = "10.0.0.12"
  $userDesktopVMSize = $smallVmSize
  $userDesktopOU = "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training"

  # Admin Desktop Vars
  $adminDesktopVMName = "admindesktop" # Has to be lowercase
  $adminDesktopNicIpAddress = "10.0.0.13"
  $adminDesktopVMSize = $smallVmSize
  $adminDesktopOU = "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training"

  # Linux Vars
  $linuxVMName = "pwnbox" # Has to be lowercase
  $linuxNicIpAddress = "10.0.0.101"
  $linuxVMSize = $smallVmSize
  $linuxImagePublisher = "Canonical"
  $linuxImageOffer = "UbuntuServer"
  $linuxImageSku = "18.04-DAILY-LTS"

  # Create the new resource group. Runs quickly.
  try {
    Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop 
  }
  catch {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location -Tag @{"StudentCode" = $StudentCode; "Region" = $Region}
  }

  $TemplateFileParams = (Get-Content $TemplateParameterFile) -Join "`n" | ConvertFrom-Json

  # Parameters for the template and configuration
  $DeploymentParameters = @{
    StudentCode                = $StudentCode
    studentSubnetName          = $studentSubnetName
    virtualNetworkName         = $virtualNetworkName
    virtualNetworkAddressRange = $virtualNetworkAddressRange
    localAdminUsername         = $localAdminUsername
    studentAdminUsername       = $studentAdminUsername
    studentPassword            = $studentPassword
    storageAccountName         = $storageAccountName
    networkSecurityGroup       = $networkSecurityGroup
    masterResourceGroup        = $masterResourceGroup
    subscriptionId             = $subscriptionId
    windowsImagePublisher      = $windowsImagePublisher
    windowsImageOffer          = $windowsImageOffer
    windowsImageSku            = $windowsImageSku
    adAdminUsername            = $adAdminUserName
    domainName                 = $domainName
    dscUrl                     = $dscUrl
    classUrl                   = $classUrl
    adVMName                   = $adVMName
    adNicIpAddress             = $adNicIPaddress
    adVMSize                   = $adVMSize
    adDscFile                  = $adDscFile
    windows2012Sku             = $windows2012Sku
    homeVMName                 = $homeVMName
    homeNicIpAddress           = $homeNicIPaddress
    homeVMSize                 = $homeVMSize
    homeOU                     = $homeOU
    terminalServerVMName       = $terminalServerVMName
    terminalServerNicIpAddress = $terminalServerNicIPaddress
    terminalServerVMSize       = $terminalServerVMSize
    terminalServerOU           = $terminalServerOU
    userDesktopVMName          = $userDesktopVMName
    userDesktopNicIpAddress    = $userDesktopNicIPaddress
    userDesktopVMSize          = $userDesktopVMSize
    userDesktopOU              = $userDesktopOU
    adminDesktopVMName         = $adminDesktopVMName
    adminDesktopNicIpAddress   = $adminDesktopNicIPaddress
    adminDesktopVMSize         = $adminDesktopVMSize
    adminDesktopOU             = $adminDesktopOU
    linuxVMName                = $linuxVMName
    linuxNicIpAddress          = $linuxNicIPaddress
    linuxVMSize                = $linuxVMSize
    linuxImagePublisher        = $linuxImagePublisher
    linuxImageOffer            = $linuxImageOffer
    linuxImageSku              = $linuxImageSku
    BackupUserName             = $TemplateFileParams.Parameters.BackupUsername.value
    BackupUserPassword         = $TemplateFileParams.Parameters.BackupUserPassword.value
    AccountingUserName         = $TemplateFileParams.Parameters.AccountingUserName.value
    AccountingUserPassword     = $TemplateFileParams.Parameters.AccountingUserPassword.value
    HelpDeskUserName           = $TemplateFileParams.Parameters.HelpDeskUserName.value
    HelpDeskUserPassword       = $TemplateFileParams.Parameters.HelpDeskUserPassword.value
    ServerAdminUsername        = $TemplateFileParams.Parameters.ServerAdminUsername.value
    ServerAdminPassword        = $TemplateFileParams.Parameters.ServerAdminPassword.value
    HelperAccountUsername      = $TemplateFileParams.Parameters.HelperAccountUsername.value
    HelperAccountPassword      = $TemplateFileParams.Parameters.HelperAccountPassword.value
    LinuxAdminUsername         = $TemplateFileParams.Parameters.LinuxAdminUsername.value
    SSHKeyData                 = $TemplateFileParams.Parameters.SSHKeyData.value
  }

  if ($Test) {
    $SplatParams = @{
      TemplateFile            = $TemplateFile
      ResourceGroupName       = $resourceGroupName 
      TemplateParameterObject = $DeploymentParameters
    }
    Test-AzureRmResourceGroupDeployment @SplatParams -Verbose
  }
  else {
    # Splat the parameters on New-AzureRmResourceGroupDeployment  
    $SplatParams = @{
      TemplateFile            = $TemplateFile 
      ResourceGroupName       = $resourceGroupName 
      TemplateParameterObject = $DeploymentParameters
      Name                    = $studentCode + "-template"
    }
    try {
      New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop @SplatParams
      $deployed = $true
    }
    catch {
      Write-Error "New-AzureRmResourceGroupDeployment failed."
      Write-Output "Error Message:"
      Write-Output $_.Exception.Message
      Write-Output $_.Exception.ItemName
      $deployed = $false
    }
    
    $ipInfo = ( 
      @{
        "vmName" = $studentCode
        "region" = $Region
      }
    )

    if ($deployed) {
      forEach ($item in $ipInfo) {
        $record = (New-AzureRmDnsRecordConfig -Cname "$StudentCode.$Region.cloudapp.azure.com")
        New-AzureRmDnsRecordSet -Name $StudentCode -RecordType "CNAME" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
        $record = (New-AzureRmDnsRecordConfig -Cname "$StudentCode-linux.$Region.cloudapp.azure.com")
        New-AzureRmDnsRecordSet -Name "$StudentCode-linux" -RecordType "CNAME" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
      }
    }
  }
}