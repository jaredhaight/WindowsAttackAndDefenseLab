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
  
  Write-Output "$place/$total - Starting deployment for $studentCode"  

  # Check if logged in to Azure
  Try {
    Get-AzureRMContext -ErrorAction Stop
  }
  Catch {
    Add-AzureRmAccount -Credential $credentials
  }


  
  # Common Variables
  $location = $region
  $locationName = "East US"
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
  $TemplateFile = './azuredeploy.json'
  $artifactsLocation = "https://raw.githubusercontent.com/jaredhaight/WindowsAttackAndDefenseLab/master/WindowsAttackAndDefenseLab/"
  $networkSecurityGroup = "waad.training-nsg-" + $region
  $subscriptionId = (Get-AzureRmContext).Subscription.SubscriptionId
  $windowsImagePublisher = "MicrosoftWindowsServer"
  $windowsImageOffer = "WindowsServer"
  $windowsImageSku = "2016-Datacenter"
  $filesUrl = "https://waadtraining.blob.core.windows.net/files/"

  # DC Variables
  $adAdminUserName = "WaadAdmin"
  $domainName = "ad." + $dnsZone
  $adVMName = "dc01"
  $adNicIPAddress = "10.0.0.4"
  $adVmSize = "Standard_A1_v2"

  # Home Vars
  $homeVMName = "Home"
  $homeNicIpAddress = "10.0.0.10"
  $homeVMSize = "Standard_A2_v2"
  $homeOU = "OU=Computers,OU=Class,DC=ad,DC=waad,DC=training"

  # Terminal Server Vars
  $terminalServerVMName = "TerminalServer"
  $terminalServerNicIpAddress = "10.0.0.11"
  $terminalServerVMSize = "Standard_A1_v2"
  $terminalServerOU = "OU=Servers,OU=Production,DC=ad,DC=waad,DC=training"

  # User Desktop Vars
  $userDesktopVMName = "Desktop"
  $userDesktopNicIpAddress = "10.0.0.11"
  $userDesktopVMSize = "Standard_A1_v2"
  $userDesktopOU = "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training"

  # Linux Vars
  $linuxVMName = $studentCode + "-lnx"
  $linuxNicIpAddress = "10.0.0.12"
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

  # Parameters for the template and configuration
  $MyParams = @{
    artifactsLocation = $artifactsLocation
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
    BackupExecPassword = $BackupExecPassword
    adAdminUsername = $adAdminUserName
    domainName = $domainName
	  filesUrl = $filesUrl
    adVMName = $adVMName
    adNicIpAddress = $adNicIPaddress
    adVMSize = $adVMSize
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
    linuxVMName = $linuxVMName
    linuxNicIpAddress = $linuxNicIPaddress
    linuxVMSize = $linuxVMSize
    linuxImagePublisher = $linuxImagePublisher
    linuxImageOffer = $linuxImageOffer
    linuxImageSku = $linuxImageSku
  }



  if ($Test) {
    $SplatParams = @{
      TemplateFile = $TemplateFile
      TemplateParameterFile = $TemplateParamaterFile
      ResourceGroupName = $resourceGroupName 
      TemplateParameterObject = $MyParams
    }
    Test-AzureRmResourceGroupDeployment @SplatParams -Verbose
  }
  else {
    # Splat the parameters on New-AzureRmResourceGroupDeployment  
    $SplatParams = @{
      TemplateUri = $TemplateFile 
      TemplateParameterFile = $TemplateParamaterFile
      ResourceGroupName = $resourceGroupName 
      TemplateParameterObject = $MyParams
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