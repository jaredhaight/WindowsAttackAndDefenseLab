function Create-WaadSnapshots {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$true)]
    [pscredential]$Credentials
  )

  $vms = Get-AzureRmVm

  forEach ($vm in $vms) {
    $snap
  }
}