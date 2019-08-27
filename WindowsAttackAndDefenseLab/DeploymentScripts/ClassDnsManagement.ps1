function New-ClassDnsRecordSets {
  [CmdletBinding()] 
  Param(
    [string]$ResourceGroupName='waad.training-master',
    [string]$ZoneName='waad.training'
  )

  $vms = Get-AzureRmResource -ResourceType "Microsoft.Compute/VirtualMachines" -Tag @{"displayName"="homeVM"}

  ForEach ($vm in $vms) {
    $studentCode = $vm.Tags['studentCode']
    $AzureHostname = "$studentCode.$($vm.Location).cloudapp.azure.com"
    $CnameRecord = New-AzDnsRecordConfig -Cname $AzureHostname
    Write-Output "[i] Mapping $AzureHostname to $studentCode.$ZoneName"
    New-AzDnsRecordSet -Name $studentCode -RecordType "CNAME" -ZoneName $ZoneName -ResourceGroupName $ResourceGroupName -Ttl 10 -DnsRecords $CnameRecord | Out-Null
  }
}


workflow Remove-ClassDnsRecordSets {
  
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ZoneName
    
  )

  $dnsRecordSets = Get-AzDnsRecordSet -ZoneName $zoneName -ResourceGroupName $resourceGroupName
 
  if ($dnsRecordSets.Count -gt 0) {
    forEach -parallel -throttle 30 ($dnsRecordSet in $dnsRecordSets) {
      if ($dnsRecordSet.RecordType -eq "A" -and $dnsRecordSet.Name -notlike "*www*") {
        $dnsName = $dnsRecordSet.Name.toString()
        Write-Output "Removing $dnsName"
        Remove-AzDnsRecordSet -Name $dnsRecordSet.Name -RecordType "A" -ZoneName $zoneName -ResourceGroupName $resourceGroupName
      }
    }
  }
  else {
    Write-Output "No DNS RecordSets found"
  }
}