Import-Module AzureRM
function New-ClassDnsRecordSets {
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials,
    [string]$ResourceGroupName='waad.training-master',
    [string]$ZoneName='waad.training'
  )
  if ((Get-AzureRmContext).Account -eq $null) {
    Connect-AzureRmAccount -Credential $Credentials
  }

  $vms = Get-AzureRmResource -ResourceType "Microsoft.Compute/VirtualMachines" -Tag @{"displayName"="homeVM"}

  ForEach ($vm in $vms) {
    $studentCode = $vm.Tags['studentCode']
    $AzureHostname = "$studentCode.$($vm.Location).cloudapp.azure.com"
    $CnameRecord = New-AzureRmDnsRecordConfig -Cname $AzureHostname
    Write-Output "[i] Mapping $AzureHostname to $studentCode.$ZoneName"
    New-AzureRmDnsRecordSet -Name $studentCode -RecordType "CNAME" -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl 10 -DnsRecords $CnameRecord | Out-Null
  }
}


workflow Remove-AllAzureRmDnsRecordSets {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ZoneName
    
  )
  $username = $credentials.UserName.ToString()
  Write-Output "Logging in as $username"
  Add-AzureRmAccount -Credential $credentials
  $dnsRecordSets = Get-AzureRMDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroupName
 
  if ($dnsRecordSets.Count -gt 0) {
    forEach -parallel -throttle 30 ($dnsRecordSet in $dnsRecordSets) {
      if ($dnsRecordSet.RecordType -eq "A" -and $dnsRecordSet.Name -notlike "*www*") {
        Add-AzureRmAccount -Credential $credentials
        $dnsName = $dnsRecordSet.Name.toString()
        Write-Output "Removing $dnsName"
        Remove-AzureRmDnsRecordSet -Name $dnsRecordSet.Name -RecordType "A" -ZoneName $zoneName -ResourceGroupName $resourceGroupName
      }
    }
  }
  else {
    Write-Output "No DNS RecordSets found"
  }
}