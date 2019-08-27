workflow New-ClassDeployment {
  param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    [string]$WorkPath
  )

  $students = Import-Csv $CsvPath

  forEach -Parallel ($student in $students) {
    Invoke-CreateWindowsAttackAndDefenseLab -StudentCode $student.Code -Region $student.Region -TemplateFile $WorkPath\azuredeploy.json -TemplateParameterFile $WorkPath\azuredeploy.parameters.json
  }
}


function Invoke-CreateWindowsAttackAndDefenseLab {
  [CmdletBinding()]
  Param(  
    [Parameter(Mandatory = $True)]
    [string]$StudentCode,
    [string]$TemplateFile = ".\azuredeploy.json",
    [string]$TemplateParameterFile = ".\azuredeploy.parameters.json",
    [string]$Region = "eastus2",
    [int]$place = 1,
    [int]$total = 1,
    [switch]$Test
  )
  
  Write-Progress -Activity "Deploying." -Status "Deploying.." -CurrentOperation "[$place/$total] Deployment for $studentCode running.."
  
  # Common Variables
  try {
    $subscriptionId = (Get-AzContext).Subscription.SubscriptionId
  }
  catch {
    Write-Error "Not logged into Azure"
    break
  }

  try {
    Get-AzResourceGroup -Name $StudentCode -Location $Region -ErrorAction Stop 
  }
  catch {
    New-AzResourceGroup -Name $StudentCode -Location $Region -Tag @{"StudentCode" = $StudentCode; "Region" = $Region }
  }
  
  $TemplateFileParams = (Get-Content $TemplateParameterFile) -Join "`n" | ConvertFrom-Json
  
  # Parameters for the template and configuration
  $DeploymentParameters = @{
    StudentCode            = $StudentCode
    subscriptionId         = $subscriptionId    
    studentPassword        = "$($TemplateFileParams.Parameters.StudentPassword.value)$StudentCode"
    BackupUserName         = $TemplateFileParams.Parameters.BackupUsername.value
    BackupUserPassword     = $TemplateFileParams.Parameters.BackupUserPassword.value
    AccountingUserName     = $TemplateFileParams.Parameters.AccountingUserName.value
    AccountingUserPassword = $TemplateFileParams.Parameters.AccountingUserPassword.value
    HelpDeskUserName       = $TemplateFileParams.Parameters.HelpDeskUserName.value
    HelpDeskUserPassword   = $TemplateFileParams.Parameters.HelpDeskUserPassword.value
    ServerAdminUsername    = $TemplateFileParams.Parameters.ServerAdminUsername.value
    ServerAdminPassword    = $TemplateFileParams.Parameters.ServerAdminPassword.value
    HelperAccountUsername  = $TemplateFileParams.Parameters.HelperAccountUsername.value
    HelperAccountPassword  = $TemplateFileParams.Parameters.HelperAccountPassword.value
    SQLAdminUsername     = $TemplateFileParams.Parameters.SQLAdminUsername.value
    SQLAdminPassword     = $TemplateFileParams.Parameters.SQLAdminPassword.value
    LinuxAdminUsername     = $TemplateFileParams.Parameters.LinuxAdminUsername.value
    SSHKeyData             = $TemplateFileParams.Parameters.SSHKeyData.value
    DCClassFolderUrl       = $TemplateFileParams.Parameters.DCClassFolderUrl.value
    UserDesktopClassFolderUrl = $TemplateFileParams.Parameters.UserDesktopClassFolderUrl.value
    LinuxClassFolderUrl    = $TemplateFileParams.Parameters.LinuxClassFolderUrl.value
    HomeClassFolderUrl     = $TemplateFileParams.Parameters.HomeClassFolderUrl.value
    HomeAppsFolderUrl     = $TemplateFileParams.Parameters.HomeAppsFolderUrl.value
    WAADFolderUrl          = $TemplateFileParams.Parameters.WAADFolderUrl.value

  }
  $sleep = Get-Random -Minimum 1 -Maximum 8
  Write-Host "Sleeping for $sleep seconds"
  Start-Sleep -Seconds $sleep
  # Splat the parameters on New-AzResourceGroupDeployment  
  $SplatParams = @{
    TemplateFile            = $TemplateFile 
    ResourceGroupName       = $StudentCode 
    TemplateParameterObject = $DeploymentParameters
    Name                    = $studentCode + "-template"
  }
  try {
    New-AzResourceGroupDeployment -Verbose -ErrorAction Stop @SplatParams
    $deployed = $true
  }
  catch {
    Write-Error "New-AzResourceGroupDeployment failed."
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
      $record = (New-AzDnsRecordConfig -Cname "$StudentCode.$Region.cloudapp.azure.com")
      New-AzDnsRecordSet -Name $StudentCode -RecordType "CNAME" -ZoneName "waad.training" -ResourceGroupName "waad.training-master" -Ttl 10 -DnsRecords $record
      $record = (New-AzDnsRecordConfig -Cname "$StudentCode-linux.$Region.cloudapp.azure.com")
      New-AzDnsRecordSet -Name "$StudentCode-linux" -RecordType "CNAME" -ZoneName "waad.training" -ResourceGroupName "waad.training-master" -Ttl 10 -DnsRecords $record
    }
  }
}