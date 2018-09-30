param(
  $ComputerName
)

try {
  Remove-Computer -ComputerName $ComputerName -Force
}
catch {
  Write-Output "Computer $ComputerName does not exist in domain"
}