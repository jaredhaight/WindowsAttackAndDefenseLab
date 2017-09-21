function New-AzureLabAccessRule {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$True)]
    [pscredential]$Credentials,

    [Parameter(Mandatory=$True)]
    [string]$SourceIpAddress,
    
    [int]$Port=3389,
    
    [string]$ResourceGroup="waad.training-master",
    
    [string[]]$NetworkSecurityGroups=('waad.training-nsg-eastus2','waad.training-nsg-westus2')
  )

  # Import Azure Service Management module
  Import-Module Azure
  Import-Module AzureRM  

  # Check if logged in to Azure
  Try {
    Get-AzureRMContext -ErrorAction Stop
  }
  Catch {
    Add-AzureRmAccount -Credential $Credentials
  }

  forEach ($nsgName in $NetworkSecurityGroups) {
    $nsg = Get-AzureNetworkSecurityGroup -Name $nsgName
    Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name 'RDP' -Direction Inbound `
      -Access Allow -SourceAddressPrefix $SourceIPAddress -SourcePortRange '*' -DestinationAddressPrefix '*' `
      -DestinationPortRange $Port -Protocol TCP
  Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg
  }
}