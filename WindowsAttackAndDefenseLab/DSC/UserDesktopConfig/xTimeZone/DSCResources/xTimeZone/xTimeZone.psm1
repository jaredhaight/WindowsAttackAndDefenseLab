#---------------------------------------------------------------------------------
#The sample scripts are not supported under any Microsoft standard support
#program or service. The sample scripts are provided AS IS without warranty
#of any kind. Microsoft further disclaims all implied warranties including,
#without limitation, any implied warranties of merchantability or of fitness for
#a particular purpose. The entire risk arising out of the use or performance of
#the sample scripts and documentation remains with you. In no event shall
#Microsoft, its authors, or anyone else involved in the creation, production, or
#delivery of the scripts be liable for any damages whatsoever (including,
#without limitation, damages for loss of business profits, business interruption,
#loss of business information, or other pecuniary loss) arising out of the use
#of or inability to use the sample scripts or documentation, even if Microsoft
#has been advised of the possibility of such damages
#---------------------------------------------------------------------------------
#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename xTimeZone.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename xTimeZone.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\TimezoneHelper.psm1" -Verbose:$false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TimeZone
    )

    # Get the current TimeZone Id
    $CurrentTimeZone = Get-TimeZoneId

    $returnValue = @{
        TimeZone = $CurrentTimeZone
        IsSingleInstance = 'Yes'
    }

    # Output the target resource
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TimeZone
    )

    $CurrentTimeZone = Get-TimeZoneId

    if($PSCmdlet.ShouldProcess("'$TimeZone'",$LocalizedData.ReplaceSystemTimezoneMessage))
    {
        if($CurrentTimeZone -ne $TimeZone)
        {
            Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage)
            Set-TimeZoneId -TimeZone $TimeZone
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.TimezoneAlreadySetMessage `
                -f $Timezone)
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TimeZone
    )
    return Test-TimeZoneId -TimeZoneId $TimeZone
}

Export-ModuleMember -Function *-TargetResource
