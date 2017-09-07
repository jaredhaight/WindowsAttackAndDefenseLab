workflow New-WindowsAttackAndDefenseLab {
  [CmdletBinding()]
  Param( 
    [Parameter(Mandatory=$True,Position=1)]
    [pscredential]$Credential,

    [Parameter(Mandatory=$True,Position=2)]
    [string]$CsvSource
  ) 

  $studentData = Import-CSV $csvSource
  foreach -parallel -throttle 20 ($student in $studentData) {
     $studentPassword = $student.password
     $studentCode = $student.code.toString()
     $studentNumber = $student.id
     $region = 'eastus2'
     
     if ($studentNumber % 2 -eq 0) {
       $region = 'westus2'
     }
     Write-Output "Sending $studentCode to $region"
     Invoke-CreateWindowsAttackAndDefenseLab -credentials $credentials -studentCode $studentCode -studentPassword $studentPassword -region $region -place $studentNumber -total $studentData.count
   }
}

function Invoke-CreateWindowsAttackAndDefenseLab {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory=$True)]
    [string]$StudentCode,
    
    [Parameter(Mandatory=$True)]
    [string]$StudentPassword,
    [string]$Region="eastus2",
    [int]$place=1,
    [int]$total=1,
    [switch]$Test
  )

  # Import Azure Service Management module
  Import-Module AzureRM

  Write-Progress -Activity "Deploying." -Status "[$place/$total] Deployment for $studentCode running.."  

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
  $publicIpName = $studentCode + "-pip"
  $localAdminUsername = "localadmin"
  $studentAdminUsername = "studentadmin"
  $storageAccountName = $studentCode + "storage"    # Lowercase required
  $TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot,'..\azuredeploy.json'))
  $TemplateParameterFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..\azuredeploy.parameters.json'))
  $networkSecurityGroup = "waad.training-nsg-" + $region
  $subscriptionId = (Get-AzureRmContext).Subscription.SubscriptionId
  $windowsImagePublisher = "MicrosoftWindowsServer"
  $windowsImageOffer = "WindowsServer"
  $windowsImageSku = "2016-Datacenter"  
  $dscUrl = "https://waadtraining.blob.core.windows.net/bootstraps/"
  $classUrl = "https://waadtraining.blob.core.windows.net/class/"


  # DC Variables
  $adAdminUserName = "WaadAdmin"
  $domainName = "ad." + $dnsZone
  $adVMName = "dc01"
  $adNicIPAddress = "10.0.0.4"
  $adVmSize = "Standard_A1_v2"
  $domainControllerImageSku = "2012-R2-Datacenter"

  # Home Vars
  $homeVMName = "home" # Has to be lowercase
  $homeNicIpAddress = "10.0.0.10"
  $homeVMSize = "Standard_A2_v2"
  $homeOU = "OU=Computers,OU=Class,DC=ad,DC=waad,DC=training"

  # Terminal Server Vars
  $terminalServerVMName = "terminalserver" # Has to be lowercase
  $terminalServerNicIpAddress = "10.0.0.11"
  $terminalServerVMSize = "Standard_A1_v2"
  $terminalServerOU = "OU=Servers,OU=Production,DC=ad,DC=waad,DC=training"

  # User Desktop Vars
  $userDesktopVMName = "userdesktop" # Has to be lowercase
  $userDesktopNicIpAddress = "10.0.0.12"
  $userDesktopVMSize = "Standard_A1_v2"
  $userDesktopOU = "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training"

  # Admin Desktop Vars
  $adminDesktopVMName = "admindesktop" # Has to be lowercase
  $adminDesktopNicIpAddress = "10.0.0.13"
  $adminDesktopVMSize = "Standard_A1_v2"
  $adminDesktopOU = "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training"

  # Linux Vars
  $linuxVMName = "pwnbox" # Has to be lowercase
  $linuxNicIpAddress = "10.0.0.101"
  $linuxVMSize = "Standard_A1_v2"
  $linuxImagePublisher = "Canonical"
  $linuxImageOffer = "UbuntuServer"
  $linuxImageSku = "16.04.0-LTS"

  # Create the new resource group. Runs quickly.
  try {
    Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
  }
  catch {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
  }

  $TemplateFileParams = (Get-Content $TemplateParameterFile) -Join "`n" | ConvertFrom-Json

  # Parameters for the template and configuration
  $DeploymentParameters = @{
    StudentCode = $StudentCode
    studentSubnetName = $studentSubnetName
    virtualNetworkName = $virtualNetworkName
    virtualNetworkAddressRange = $virtualNetworkAddressRange
    publicIpName = $publicIpName
    localAdminUsername = $localAdminUsername
    studentAdminUsername = $studentAdminUsername
    studentPassword = $studentPassword
    storageAccountName = $storageAccountName
    networkSecurityGroup = $networkSecurityGroup
    masterResourceGroup = $masterResourceGroup
    subscriptionId = $subscriptionId
    windowsImagePublisher = $windowsImagePublisher
    windowsImageOffer = $windowsImageOffer
    windowsImageSku = $windowsImageSku
    adAdminUsername = $adAdminUserName
    domainName = $domainName
    dscUrl = $dscUrl
    classUrl = $classUrl
    adVMName = $adVMName
    adNicIpAddress = $adNicIPaddress
    adVMSize = $adVMSize
    domainControllerImageSku = $domainControllerImageSku
    homeVMName = $homeVMName
    homeNicIpAddress = $homeNicIPaddress
    homeVMSize = $homeVMSize
    homeOU = $homeOU
    terminalServerVMName = $terminalServerVMName
    terminalServerNicIpAddress = $terminalServerNicIPaddress
    terminalServerVMSize = $terminalServerVMSize
    terminalServerOU = $terminalServerOU
    userDesktopVMName = $userDesktopVMName
    userDesktopNicIpAddress = $userDesktopNicIPaddress
    userDesktopVMSize = $userDesktopVMSize
    userDesktopOU = $userDesktopOU
    adminDesktopVMName = $adminDesktopVMName
    adminDesktopNicIpAddress = $adminDesktopNicIPaddress
    adminDesktopVMSize = $adminDesktopVMSize
    adminDesktopOU = $adminDesktopOU
    linuxVMName = $linuxVMName
    linuxNicIpAddress = $linuxNicIPaddress
    linuxVMSize = $linuxVMSize
    linuxImagePublisher = $linuxImagePublisher
    linuxImageOffer = $linuxImageOffer
    linuxImageSku = $linuxImageSku
    BackupUserName = $TemplateFileParams.Parameters.BackupUsername.value
    BackupUserPassword = $TemplateFileParams.Parameters.BackupUserPassword.value
    AccountingUserName = $TemplateFileParams.Parameters.AccountingUserName.value
    AccountingUserPassword = $TemplateFileParams.Parameters.AccountingUserPassword.value
    HelpDeskUserName = $TemplateFileParams.Parameters.HelpDeskUserName.value
    HelpDeskUserPassword = $TemplateFileParams.Parameters.HelpDeskUserPassword.value
    ServerAdminUsername = $TemplateFileParams.Parameters.ServerAdminUsername.value
    ServerAdminPassword = $TemplateFileParams.Parameters.ServerAdminPassword.value
  }

  if ($Test) {
    $SplatParams = @{
      TemplateFile = $TemplateFile
      ResourceGroupName = $resourceGroupName 
      TemplateParameterObject = $DeploymentParameters
    }
    Test-AzureRmResourceGroupDeployment @SplatParams -Verbose
  }
  else {
    # Splat the parameters on New-AzureRmResourceGroupDeployment  
    $SplatParams = @{
      TemplateFile = $TemplateFile 
      ResourceGroupName = $resourceGroupName 
      TemplateParameterObject = $DeploymentParameters
      Name = $studentCode + "-template"
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
        "publicIpName" = $publicIpName
        "vmName" = $studentCode
      }
    )

    if ($deployed) {
      forEach ($item in $ipInfo) {
        $pip = Get-AzureRmPublicIpAddress -Name $item.publicIpName -ResourceGroupName $resourceGroupName
        $record = (New-AzureRmDnsRecordConfig -IPv4Address $pip.IpAddress)
        $rs = New-AzureRmDnsRecordSet -Name $item.vmName -RecordType "A" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
      }
    }
  }
}