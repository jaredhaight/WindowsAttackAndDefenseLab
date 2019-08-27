Import-Module Az
  
workflow Remove-ClassResourceGroups {
  
  $resourceGroups = Get-AzResourceGroup
 
  if ($resourceGroups.Count -gt 0) {
    forEach -parallel -throttle 30 ($resourceGroup in $resourceGroups) {
        $resourceGroupName = $resourceGroup.ResourceGroupName.toString()
        if ($resourceGroupName -notlike "*master" -and $resourceGroupName -notlike "cupcake*" -and $resourceGroupName -notlike "jah*") {
            Write-Output "[*] Removing $resourceGroupName.."
            Remove-AzResourceGroup -Name $resourceGroupName -Force
        }
    }
  }
  else {
    Write-Output "No Resource Groups Found"
  }

}