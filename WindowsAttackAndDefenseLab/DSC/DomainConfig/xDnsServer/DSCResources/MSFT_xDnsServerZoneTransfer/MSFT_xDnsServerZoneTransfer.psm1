Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Allow transfer to any server use 0, to one in name tab 1, specific one 2, no transfer 3
$XferId2Name= @('Any','Named','Specific','None')

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
CheckingZoneMessage       = Checking the current zone transfer for DNS server zone {0} ...
DesiredZoneMessage        = Current zone transfer settings for the given DNS server zone is correctly set to {0}
NotDesiredZoneMessage     = DNS server zone transfer settings is not correct. Expected {0}, actual {1}
SetZoneMessage            = Current zone transfer setting for DNS server zone {0} is set to {1}

NotDesiredPropertyMessage = DNS server zone transfer secondary servers are not correct. Expected {0}, actual {1}
SettingPropertyMessage    = Setting DNS server zone transfer secondary servers to {0} ...
SetPropertyMessage        = DNS server zone transfer secondary servers are set
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [ValidateSet("None","Any","Named","Specific")]
        [String]$Type
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

    $currentZone = Get-CimInstance `
        -ClassName MicrosoftDNS_Zone `
        -Namespace root\MicrosoftDNS `
        -Verbose:$false | Where-Object {$_.Name -eq $Name}

    @{
        Name            = $Name
        Type            = $XferId2Name[$currentZone.SecureSecondaries]
        SecondaryServer = $currentZone.SecondaryServers
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [ValidateSet("None","Any","Named","Specific")]
        [String]$Type,

        [String[]]$SecondaryServer
    )

    if($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    Validate-ResourceProperties @PSBoundParameters -Apply

    # Restart the DNS service
    Restart-Service -Name DNS
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [ValidateSet("None","Any","Named","Specific")]
        [String]$Type,

        [String[]]$SecondaryServer
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

    if($PSBoundParameters.ContainsKey('Debug'))
    {
        $null = $PSBoundParameters.Remove('Debug')
    }
    Validate-ResourceProperties @PSBoundParameters
}

function Validate-ResourceProperties
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [ValidateSet("None","Any","Named","Specific")]
        [String]$Type,

        [String[]]$SecondaryServer,

        [Switch]$Apply
    )

    $checkZoneMessage = $($LocalizedData.CheckingZoneMessage) `
        -f $Name
    Write-Verbose -Message $checkZoneMessage
 
    # Get the current value of transfer zone
    $currentZone = Get-CimInstance `
        -ClassName MicrosoftDNS_Zone `
        -Namespace root\MicrosoftDNS `
        -Verbose:$false | Where-Object {$_.Name -eq $Name}
    $currentZoneTransfer = $currentZone.SecureSecondaries

    # Hashtable with 2 keys: SecureSecondaries,SecondaryServers
    $Arguments = @{}

    switch ($Type)
    {
        'None'
        {
            $Arguments['SecureSecondaries'] = 3
        }
        'Any'
        {
            $Arguments['SecureSecondaries'] = 0
        }
        'Named'
        {
            $Arguments['SecureSecondaries'] = 1
        }
        'Specific'
        {
            $Arguments['SecureSecondaries'] = 2
            $Arguments['SecondaryServers']=$SecondaryServer
        }
    }

    # Check the current value against expected value
    if($currentZoneTransfer -eq $Arguments.SecureSecondaries)
    {
        $desiredZoneMessage = ($LocalizedData.DesiredZoneMessage) `
            -f $XferId2Name[$currentZoneTransfer]
        Write-Verbose -Message $desiredZoneMessage

        # If the Type is specific, and SecondaryServer doesn't match
        if(($currentZoneTransfer -eq 2) `
            -and (Compare-Object $currentZone.SecondaryServers $SecondaryServer))
        {
            $notDesiredPropertyMessage = ($LocalizedData.NotDesiredPropertyMessage) `
                -f ($SecondaryServer -join ','),($currentZone.SecondaryServers -join ',')
            Write-Verbose -Message $notDesiredPropertyMessage

            # Set the SecondaryServer property
            if($Apply)
            {
                $settingPropertyMessage = ($LocalizedData.SettingPropertyMessage) `
                    -f ($SecondaryServer -join ',')
                Write-Verbose -Message $settingPropertyMessage
                
                $null = Invoke-CimMethod `
                    -InputObject $currentZone `
                    -MethodName ResetSecondaries `
                    -Arguments $Arguments `
                    -Verbose:$false

                $setPropertyMessage = $LocalizedData.SetPropertyMessage
                Write-Verbose -Message $setPropertyMessage
            }
            else
            {
                return $false
            }
        } # end SecondaryServer match

        if(-not $Apply)
        {
            return $true
        }
    } # end currentZoneTransfer -eq ExpectedZoneTransfer
    else
    {
        $notDesiredZoneMessage = $($LocalizedData.NotDesiredZoneMessage) `
            -f $XferId2Name[$Arguments.SecureSecondaries], `
               $XferId2Name[$currentZoneTransfer]
        Write-Verbose -Message $notDesiredZoneMessage

        if($Apply)
        {
            $null = Invoke-CimMethod `
                -InputObject $currentZone `
                -MethodName ResetSecondaries `
                -Arguments $Arguments `
                -Verbose:$false

            $setZoneMessage = $($LocalizedData.SetZoneMessage) `
                -f $Name,$XferId2Name[$Arguments.SecureSecondaries]
            Write-Verbose -Message $setZoneMessage
        }
        else
        {
            return $false
        }
    } # end currentZoneTransfer -ne ExpectedZoneTransfer
}

Export-ModuleMember -Function *-TargetResource
