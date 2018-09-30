param(
  $StudentPassword
)

$password = ConvertTo-SecureString -String $StudentPassword -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('AD\WaadAdmin',$password)

Add-Computer -DomainName 'ad.waad.training' -Credential $credential -OUPath "OU=Computers,OU=Production,DC=ad,DC=waad,DC=training" -Force
