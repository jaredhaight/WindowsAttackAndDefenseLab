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


###############################################################################################
#### The below is modified from: https://gist.github.com/stuartleeks/1dbe648bbfdc2a56f481  ####
###############################################################################################

<#
 # Helper function for other cmdlets
 #>
 function ParseOperationDuration($durationString){

  # expected behaviour (should put in tests)
  #(ParseOperationDuration "PT21.501S").ToString() # Timespan: 21.501 seconds
  #(ParseOperationDuration "PT5M21.501S").ToString() # Timespan: 5 minutes 21.501 seconds
  #(ParseOperationDuration "PT1H5M21.501S").ToString() # Timespan: 1 hour 5 minutes 21.501 seconds
  #(ParseOperationDuration "PT 21.501S").ToString() # throws exception for unhandled format
  
      $timespan = $null
      switch -Regex ($durationString)  {
          "^PT(?<seconds>\d*.\d*)S$" {
              $timespan =  New-TimeSpan -Seconds $matches["seconds"]
          }
          "^PT(?<minutes>\d*)M(?<seconds>\d*.\d*)S$" {
              $timespan =  New-TimeSpan -Minutes $matches["minutes"] -Seconds $matches["seconds"]
          }
          "^PT(?<hours>\d*)H(?<minutes>\d*)M(?<seconds>\d*.\d*)S$" {
              $timespan =  New-TimeSpan -Hours $matches["hours"] -Minutes $matches["minutes"] -Seconds $matches["seconds"]
          }
      }
      if($null -eq $timespan){
          $message = "unhandled duration format '$durationString'"
          throw $message
      }
      $timespan
  }
  
  <#
  .SYNOPSIS
  
  Get a summary of Azure Resource Group Deployment Operations
  .DESCRIPTION
  
  Converts the output from Get-AzResourceGroupDeploymentOperation into a summary object with commonly used information, and parses durations into TimeSpans etc
  
  .PARAMETER DeploymentOperations
  
  .EXAMPLE
  
  Get-AzResourceGroupDeploymentOperation -ResourceGroupName "mygroup" -DeploymentName "my deployment" | ConvertTo-DeploymentOperationSummary
  
  #>
  function ConvertTo-DeploymentOperationSummary{
      [CmdletBinding()]
      param(
      
          [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$True)]
          [object[]] $DeploymentOperations,
          [switch]$Failed
      )
      begin {
        $deployments = @()
      }
      process{
           $DeploymentOperations | ForEach-Object { 
              $timeStamp = [System.DateTime]::Parse($_.Properties.Timestamp);
              $duration = (ParseOperationDuration $_.Properties.Duration);
              $deployments += [PSCustomObject]@{ 
                  "Id"=$_.OperationId; 
                  "ProvisioningState" = $_.Properties.ProvisioningState; 
                  "ResourceType"=$_.Properties.TargetResource.ResourceType; 
                  "ResourceName"=$_.Properties.TargetResource.ResourceName; 
                  "StartTime" = $timeStamp - $duration; 
                  "EndTime" = $timeStamp; 
                  "Duration" =  $duration;
                  "Error" = $_.Properties.StatusMessage.Error;
              }
          }
      }
      end {
        return $deployments
      }
  }
  
  <#
  .SYNOPSIS
  
  Get the latest deployment operations for an Azure resource group
  .DESCRIPTION
  
  Provides a quick way to get the latest deployment operations for an Azure resource group. 
  It defaults to the operations for the most recent deployment but that behaviour can be changed with the DeploymentsToSkip parameter.
  .PARAMETER ResourceGroupName
  The name of the resource group to get the deployment operations for
  .PARAMETER DeploymentsToSkip
  How many deployments to skip for the specified resource group. By default, the most recent deployment is used. 
  Setting this to 1 will 
  Defaults to 0
  .EXAMPLE
  Get the operations for the most recent deployment for "my group"
  
  Get-LastDeploymentOperation -ResourceGroupName "my group"
  
  .EXAMPLE
  Get the operations for the deployment before the most recent deployment for "my group"
  
  Get-LastDeploymentOperation -ResourceGroupName "my group" -DeploymentsToSkip 1
  
  #>
  function Get-LastDeploymentOperation
  {
      [CmdletBinding()]
      Param
      (
          [string]
          [Parameter(Mandatory=$true)]
          [ValidateNotNullOrEmpty()]
          $ResourceGroupName,
  
          [int]
          $DeploymentsToSkip=0
      )
      
      Get-AzResourceGroup -ResourceGroupName $ResourceGroupName `
          | Get-AzResourceGroupDeployment `
          | Sort-Object -Descending -Property Timestamp `
          | Select-Object -Skip $DeploymentsToSkip -First 1 `
          | Get-AzResourceGroupDeploymentOperation
   
  }