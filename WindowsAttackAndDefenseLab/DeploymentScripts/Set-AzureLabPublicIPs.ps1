$pips = Get-AzureRmPublicIpAddress

forEach ($pip in $pips) {
  $name = $pip.DnsSettings.domainNameLabel
  $record = (New-AzureRmDnsRecordConfig -IPv4Address $pip.IpAddress)
  New-AzureRmDnsRecordSet -Name $name -RecordType "A" -ZoneName 'waad.training' -ResourceGroupName 'waad.training-master' -Ttl 10 -DnsRecords $record
}