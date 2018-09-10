# Copyright (c) 2017 Chocolatey Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

<#
.Description
Returns the configuration for cChocoFeature.

.Example
Get-TargetResource -FeatureName allowGlobalConfirmation -Ensure 'Present'
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FeatureName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present'
    )

    Write-Verbose "Starting cChocoFeature Get-TargetResource - Feature Name: $FeatureName, Ensure: $Ensure"

    $returnValue = @{
        FeatureName = $FeatureName
        Ensure = $Ensure
    }

    $returnValue

}

<#
.Description
Performs the set for the cChocoFeature resource.

.Example
Get-TargetResource -FeatureName allowGlobalConfirmation -Ensure 'Present'

#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FeatureName,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure='Present'
    )


    Write-Verbose "Starting cChocoFeature Set-TargetResource - Feature Name: $FeatureName, Ensure: $Ensure."

    if ($pscmdlet.ShouldProcess("Choco feature $FeatureName will be ensured $Ensure."))
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose "Enabling choco feature $FeatureName."
            choco feature enable -n $FeatureName
        }
        else 
        {
            Write-Verbose "Disabling choco feature $FeatureName."
            choco feature disable -n $FeatureName
        }
    }

}

<#
.Description
Performs the test for cChocoFeature.

.Example
Test-TargetResource -FeatureName allowGlobalConfirmation -Ensure 'Present'
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FeatureName,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present'
    )

    Write-Verbose "Starting cChocoFeature Test-TargetResource - Feature Name: $FeatureName, Ensure: $Ensure."

    $result = $false
    $feature = Get-ChocoFeature -FeatureName $FeatureName | Where-Object {$_.State -eq "Enabled"}

    if (($Ensure -eq 'Present' -and ([bool]$feature)) -or ($Ensure -eq 'Absent' -and !([bool]$feature)))
    {
        Write-Verbose "Test-TargetResource is true, $FeatureName is $Ensure."
        $result = $true
    }
    else
    {
        Write-Verbose "Test-TargetResource is false, $FeatureName is not $Ensure."
    }

    return $result

}

<#
.Description
Query chocolatey features.
#>
function Get-ChocoFeature 
{
    [OutputType([PSCustomObject])]
    param(
        [string]
        $FeatureName
    )
    choco feature  -r | ConvertFrom-Csv -Delimiter "|" -Header Name, State, Description | Where-Object {$_.Name -eq $FeatureName}
}




Export-ModuleMember -Function *-TargetResource

