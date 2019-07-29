# workflow Stop-ClassVM {
#   [cmdletbinding()]
#   param(
#     [ValidateSet('LinuxVM', 'DomainControllerVM', 'HomeVM', 'ServerVM', 'All')]
#     [Parameter(Mandatory = $true)]
#     [string]$Type,
#     [Parameter(Mandatory = $true)]
#     [PSCredential]$Credential
#   )
  
#   Write-Verbose '[*] Checking if we are logged into Azure..'
  


#   if ($Type -eq 'All') {
#     Connect-AzureRmAccount -Credential $Credential
#     Write-Verbose '[*] Running the "StopVMs" runbook'
#     Start-AzureRmAutomationRunbook -Name 'StopVMs' -ResourceGroupName 'evil.training-master' -AutomationAccountName 'taskmaster-eastus2'
#   }
#   else {
#     $resources = Find-AzureRmResource -Tag @{"DisplayName" = "$type"}
#     $vms = $resources | Get-AzureRmVM
#     if ($vms -ne $null) {
#       ForEach -Parallel -ThrottleLimit 20 ($vm in $vms) {
#         Write-Verbose "[*] Stopping $($VM.Name)"
#         Connect-AzureRmAccount -Credential $credential
#         Stop-AzureRmVm -Name $($vm.Name) -ResourceGroupName $($Vm.ResourceGroupName) -Force
#       }
#     }
#     else {
#       Write-Warning "No resouces found."
      
#     }
#   }
# }

# workflow Start-ClassVM {
#   [cmdletbinding()]
#   param(
#     [ValidateSet('LinuxVM', 'DomainControllerVM', 'HomeVM', 'ServerVM', 'All')]
#     [Parameter(Mandatory = $true)]
#     [string]$Type,
#     [Parameter(Mandatory = $true)]
#     [PSCredential]$Credential
#   )

#   Connect-AzureRmAccount -Credential $credential
  
#   if ($Type -eq 'All') {
#     Write-Verbose '[*] Running the "StartVMs" runbook'
#     Start-AzureRmAutomationRunbook -Name 'StartVMs' -ResourceGroupName 'evil.training-master' -AutomationAccountName 'taskmaster-eastus2'
#   }
#   else {
#     $resources = Find-AzureRmResource -Tag @{"DisplayName" = "$type"}
#     $vms = $resources | Get-AzureRmVM
#     if ($vms -ne $null) {
#       ForEach -Parallel -ThrottleLimit 20 ($vm in $vms) {
#         Write-Verbose "[*] Starting $($VM.Name)"
#         Connect-AzureRmAccount -Credential $credential 
#         Start-AzureRmVm -Name $($vm.Name) -ResourceGroupName $($Vm.ResourceGroupName) 
#       }
#     }
#     else {
#       Write-Warning "No resouces found."
#     }
#   }
# }

# function Create-ClassVm {
#   [cmdletbinding()]
#   param(
#     $ComputerName,
#     $StudentCode,
#     $StudentPassword
#   )

#   $ArmTemplateFile = "$PSScriptRoot\..\components\$ComputerName.json"
#   $ArmTemplateParametersFile = "$PSScriptRoot\..\components\$ComputerName.parameters.json"


#   Write-Output "[*] ARM Parameters File: $ArmTemplateParametersFile"

#   $rgName = "$StudentCode.waad.training"

#   Write-Output "[*] Trying to remove $ComputerName from domain"
#   Invoke-AzureRmVMRunCommand -ResourceGroupName $rgName -VMName $ComputerName -CommandId "$ComputerName-AdUnjoin" -ScriptPath "$PSScriptRoot\..\AzureVMScripts\Remove-ComputerFromDomain.ps1" -Parameter @{"ComputerName" = $ComputerName}

#   $rg = Get-AzureRmResourceGroup $rgName
#   $network = Get-AzureRmVirtualNetwork -ResourceGroupName $rgName  
#   $TemplateFileParams = (Get-Content $ArmTemplateParametersFile) -Join "`n" | ConvertFrom-Json

#   $DeploymentParameters = @{
#     subscriptionId     = (Get-AzureRmContext).Subscription.Id
#     rgName             = $rgName
#     location           = $rg.Location
#     vnetId             = $network.Id
#     studentCode        = $StudentCode
#     studentSubnetName  = $network.Subnets[0].Name
#     virtualNetworkName = $network.Name
#     localAdminUsername = "localadmin"
#     adAdminUsername    = "WaadAdmin"
#     domainName         = "ad.waad.training"
#     adNicIPAddress     = "10.0.0.4"
#     imagePublisher     = $TemplateFileParams.Parameters.ImageProvider.Value
#     imageOffer         = $TemplateFileParams.Parameters.ImageOffer.Value
#     sku                = $TemplateFileParams.Parameters.Sku.Value
#     vmName             = $TemplateFileParams.Parameters.VmName.Value
#     ipAddress          = $TemplateFileParams.Parameters.IpAddress.Value
#     vmSize             = $TemplateFileParams.Parameters.VmSize.Value
#     vmOU               = $TemplateFileParams.Parameters.OU.Value
#     dscUrl             = "https://waadtraining.blob.core.windows.net/bootstraps/"
#     classUrl           = "https://waadtraining.blob.core.windows.net/class/"
#     studentPassword    = $studentPassword
#   }

#   Write-Output $DeploymentParameters
      
#   $SplatParams = @{
#     TemplateFile            = $ArmTemplateFile 
#     ResourceGroupName       = $rgName 
#     TemplateParameterObject = $DeploymentParameters
#     Name                    = $studentCode + "-template"
#   }

#   try {
#     New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop @SplatParams
#     $deployed = $true
#   }
#   catch {
#     Write-Error "New-AzureRmResourceGroupDeployment failed."
#     Write-Output "Error Message:"
#     Write-Output $_.Exception.Message
#     Write-Output $_.Exception.ItemName
#     $deployed = $false
#   }
# }