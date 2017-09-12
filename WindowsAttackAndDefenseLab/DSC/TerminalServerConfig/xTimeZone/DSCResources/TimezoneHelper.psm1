#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename TimezoneHelper.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename TimezoneHelper.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    .SYNOPSIS
    Internal function to throw terminating error with specified errroCategory, errorId and errorMessage
#>
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
} # function New-TerminatingError

<#
    .SYNOPSIS
    Get the of the current timezone Id.

#>
function Get-TimeZoneId
{
    [CmdletBinding()]
    param()

    if (Test-Command -Name 'Get-Timezone' -Module 'Microsoft.PowerShell.Management')
    {
        Write-Verbose -Message ($LocalizedData.GettingTimezoneMessage -f 'Cmdlets')

        $Timezone = (Get-Timezone).StandardName
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.GettingTimezoneMessage -f 'CIM')

        $TimeZone = (Get-CimInstance `
            -ClassName WIN32_Timezone `
            -Namespace root\cimv2).StandardName
    }

    Write-Verbose -Message ($LocalizedData.CurrentTimezoneMessage `
        -f $Timezone)

    $timeZoneInfo = [System.TimeZoneInfo]::GetSystemTimeZones() |
        Where-Object StandardName -eq $TimeZone

    return $timeZoneInfo.Id
} # function Get-TimeZoneId

<#
    .SYNOPSIS
    Compare a timezone Id with the current timezone Id
#>
function Test-TimeZoneId
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )
    # Test Expected is same as Current
    $currentTimeZoneId = Get-TimeZoneId

    return $TimeZoneId -eq $currentTimeZoneId
} # function Test-TimeZoneId

<#
    .SYNOPSIS
    Sets the current timezone using a timezone Id
#>
function Set-TimeZoneId
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    if (Test-Command -Name 'Set-Timezone' -Module 'Microsoft.PowerShell.Management')
    {
        Set-Timezone -Id $TimezoneId
    }
    else
    {
        if (Test-Command -Name 'Add-Type' -Module 'Microsoft.Powershell.Utility')
        {
            # We can use Reflection to modify the TimeZone
            Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage `
                -f $TimeZoneId,'.NET')

            Set-TimeZoneUsingNET -TimezoneId $TimeZoneId
        }
        else
        {
            # For anything else use TZUTIL.EXE
            Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage `
                -f $TimeZoneId,'TZUTIL.EXE')

            try
            {
                & tzutil.exe @('/s',$TimeZoneId)
            }
            catch
            {
                $ErrorMsg = $_.Exception.Message
                Write-Verbose -Message $ErrorMsg
            } # try
        } # if
    } # if

    Write-Verbose -Message ($LocalizedData.TimezoneUpdatedMessage `
        -f $TimeZone)
} # function Set-TimeZoneId

<#
    .SYNOPSIS
    This function exists so that the ::Set method can be mocked by Pester.
#>
function Set-TimeZoneUsingNET {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    # Add the [TimeZoneHelper.TimeZone] type if it is not defined.
    if (-not ([System.Management.Automation.PSTypeName]'TimeZoneHelper.TimeZone').Type)
    {
        Write-Verbose -Message ($LocalizedData.AddingSetTimeZonedotNetTypeMessage)
        $SetTimeZoneCs = Get-Content `
            -Path (Join-Path -Path $PSScriptRoot -ChildPath 'SetTimeZone.cs') `
            -Raw
        Add-Type `
            -Language CSharp `
            -TypeDefinition $SetTimeZoneCs
    } # if

    [Microsoft.PowerShell.xTimeZone.TimeZone]::Set($TimeZoneId)
} # function Set-TimeZoneUsingNET

<#
    .SYNOPSIS
    This function tests if a cmdlet exists.
#>
function Test-Command {
    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Module
    )

    return ($null -ne (Get-Command @PSBoundParameters -ErrorAction SilentlyContinue))
} # function Test-Command
