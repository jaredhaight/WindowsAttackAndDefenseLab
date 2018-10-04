workflow Add-ClassAccessRule {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory = $True)]
    [string]$SourceIpAddress,
    
    [int]$Port = 3389,
    
    [string]$ResourceGroup = "waad.training-master"
  )

  $NetworkSecurityGroups = (
    'waad.training-nsg-northcentralus',
    'waad.training-nsg-southcentralus',
    'waad.training-nsg-centralus',
    'waad.training-nsg-eastus2',
    'waad.training-nsg-westcentralus',
    'waad.training-nsg-westus2'
  )

  forEach -Parallel -Throttle 8 ($nsg in $NetworkSecurityGroups) {
    Add-AccessRule -Credentials $Credentials -SourceIpAddress $SourceIpAddress -Port $Port -ResourceGroup $ResourceGroup -NetworkSecurityGroupName $nsg
  }
}

function Add-AccessRule {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory = $True)]
    [string]$SourceIpAddress,
    
    [int]$Port = 3389,
    
    [string]$ResourceGroup = "waad.training-master",
    [string]$NetworkSecurityGroupName
  )
  $sleep = Get-Random -Minimum 1 -Maximum 3

  Write-Output "[*] Sleeping for $sleep seconds"
  Start-Sleep -Seconds $sleep 
  # Check if logged in to Azure
  Connect-AzureRmAccount -Credential $Credentials -OutVariable $null
  
  Write-Output "[*] Getting NSG: $NetworkSecurityGroupName"
  try {
    $nsg = Get-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroup -OutVariable $null
    $priorties = $nsg.SecurityRules.Priority
    if ($priorties) {
      $priority = $priorties[-1] + 1
    }
    else {
      $priority = 101
    }
    
  }
  catch {
    Write-Warning "Error Getting NSG: $NetworkSecurityGroupName"
    Write-Output $error[0]
  }

  Write-Output "[*] New rule priority: $priority"
  Write-Output "[*] Adding rule to $NetworkSecurityGroupName"
  try {
    if ($NetworkSecurityGroupName -eq 'chat-nsg') {
      $port = 443
      $ruleName = "HTTPS-$Priority"
    }
    else {
      $port = 3389
      $ruleName = "RDP-$Priority"
    }
    Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $ruleName -Direction Inbound `
      -Access Allow -SourceAddressPrefix $SourceIPAddress -SourcePortRange '*' -DestinationAddressPrefix '*' `
      -DestinationPortRange $Port -Protocol TCP -Priority $priority | Set-AzureRmNetworkSecurityGroup | Out-Null
  }
  catch {
    Write-Warning "Error adding rule to $NetworkSecurityGroupName"
    Write-Output $error[0]
  }
}

function Remove-ClassAccessRule {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$True)]
    [pscredential]$Credentials,
    [string]$ResourceGroup="waad.training-master"
  )

  $NetworkSecurityGroups = (
    'waad.training-nsg-northcentralus',
    'waad.training-nsg-southcentralus',
    'waad.training-nsg-centralus',
    'waad.training-nsg-eastus2',
    'waad.training-nsg-westcentralus',
    'waad.training-nsg-westus2'
  )
  # Check if logged in to Azure
  if ((Get-AzureRmContext).Account -eq $null) {
    Connect-AzureRmAccount -Credential $Credentials
  }

  forEach ($NetworkSecurityGroupName in $NetworkSecurityGroups) {
    Write-Output "[*] Getting NSG: $NetworkSecurityGroupName"
    try {
      $nsg = Get-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroup -OutVariable $null
    }
    catch {
      Write-Warning "Error Getting NSG: $NetworkSecurityGroupName"
      Write-Output $error[0]
      break
    }

    Write-Output "[*] Rules count: $($nsg.SecurityRules.Count)"
    while ($nsg.SecurityRules.Count -gt 0) {
      $rule = $nsg.SecurityRules[0]
      Write-Output "[*] Removing $($rule.Name)"
      try {
        Remove-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $rule.Name | Out-Null
      }
      catch {
        Write-Warning "Error removing rule from $NetworkSecurityGroupName"
        Write-Output $error[0]
        break
      }
    }
    Write-Output "[*] Setting $NetworkSecurityGroupName"
    try {
      Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg | Out-Null
    }
    catch {
      Write-Warning "Error setting $NetworkSecurityGroupName"
      Write-Output $error[0]
      break
    }
  }
}