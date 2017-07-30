Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
CheckingZoneMessage          = Checking DNS server zone with name {0} ...
TestZoneMessage              = Named DNS server zone is {0} and it should be {1} 
RemovingZoneMessage          = Removing DNS server zone ...
DeleteZoneMessage            = DNS server zone {0} is now absent

CheckingSecondaryZoneMessage = Checking if the DNS server zone is a secondary zone ...
AlreadySecondaryZoneMessage  = DNS server zone {0} is already a secondary zone
NotSecondaryZoneMessage      = DNS server zone {0} is not a secondary zone but {1} zone
AddingSecondaryZoneMessage   = Adding secondary DNS server zone  ...
NewSecondaryZoneMessage      = DNS server secondary zone {0} is now present
SetSecondaryZoneMessage      = DNS server zone {0} is now a secondary zone

CheckPropertyMessage         = Checking DNS secondary server {0} ...
NotDesiredPropertyMessage    = DNS server secondary zone {0} is not correct. Expected {1}, actual {2}
DesiredPropertyMessage       = DNS server secondary zone {0} is correct
SetPropertyMessage           = DNS server secondary zone {0} is set
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
        [String[]]$MasterServers
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

    $dnsZone = Get-DnsServerZone -Name $Name -ErrorAction SilentlyContinue
    if($dnsZone)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    @{
        Name = $Name
        Ensure = $Ensure
        MasterServers = [string[]]$($dnsZone.MasterServers.IPAddressToString)
        Type = $dnsZone.ZoneType
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
        [String[]]$MasterServers,

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present'
    )

    if($PSBoundParameters.ContainsKey('Debug')){$null = $PSBoundParameters.Remove('Debug')}
    Validate-ResourceProperties @PSBoundParameters -Apply
    
    # Restart the DNS service
    Restart-Service DNS
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
        [String[]]$MasterServers,

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present'
    )

#region Input Validation

    # Check for DnsServer module/role
    Assert-Module -moduleName DnsServer

#endregion

    if($PSBoundParameters.ContainsKey('Debug')){$null = $PSBoundParameters.Remove('Debug')}
    Validate-ResourceProperties @PSBoundParameters

}

#region Helper Functions
function Validate-ResourceProperties
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [String[]]$MasterServers,

        [ValidateSet("Present","Absent")]
        [String]$Ensure = 'Present',

        [Switch]$Apply
    )

    $zoneMessage = $($LocalizedData.CheckingZoneMessage) -f $Name
    Write-Verbose -Message $zoneMessage

    $dnsZone = Get-DnsServerZone -Name $Name -ErrorAction SilentlyContinue

    # Found DNS Zone
    if($dnsZone)
    {
        $testZoneMessage = $($LocalizedData.TestZoneMessage) -f 'present', $Ensure
        Write-Verbose -Message $testZoneMessage

        # If the zone should be present
        if($Ensure -eq 'Present')
        {
            # Check if the zone is secondary
            $secondaryZoneMessage = $LocalizedData.CheckingSecondaryZoneMessage
            Write-Verbose -Message $secondaryZoneMessage

            # If the zone is already secondary zone
            if($dnsZone.ZoneType -eq "Secondary")
            {
                $correctZoneMessage = $($LocalizedData.AlreadySecondaryZoneMessage) -f $Name
                Write-Verbose -Message $correctZoneMessage

                # Check the master server property
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'master servers'
                Write-Verbose -Message $checkPropertyMessage

                # Compare the master server property
                if((-not $dnsZone.MasterServers) -or (Compare-Object $($dnsZone.MasterServers.IPAddressToString) $MasterServers))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'master servers',$MasterServers,$dnsZone.MasterServers
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        Set-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers

                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'master servers'
                        Write-Verbose -Message $setPropertyMessage
                    }
                    else
                    {
                        return $false
                    }
                } # end master server mismatch
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'master servers'
                    Write-Verbose -Message $desiredPropertyMessage
                    if(-not $Apply)
                    {
                        return $true
                    }
                } # end master servers match

            } # end zone is already secondary

            # If the zone is not secondary, make it so
            else
            {
                $notCorrectZoneMessage = $($LocalizedData.NotSecondaryZoneMessage) -f $Name,$dnsZone.ZoneType
                Write-Verbose -Message $notCorrectZoneMessage

                # Convert the zone to Secondary zone
                if($Apply)
                {
                    ConvertTo-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers -ZoneFile $Name -Force

                    $setZoneMessage = $($LocalizedData.SetSecondaryZoneMessage) -f $Name
                    Write-Verbose -Message $setZoneMessage
                }
                else
                {
                    return $false
                }
            } # end zone is not secondary

        }# end ensure -eq present
            
        # If zone should be absent
        else
        {
            if($Apply)
            {
                $removingZoneMessage = $LocalizedData.RemovingZoneMessage
                Write-Verbose -Message $removingZoneMessage

                Remove-DnsServerZone -Name $Name -Force

                $deleteZoneMessage = $($LocalizedData.DeleteZoneMessage) -f $Name
                Write-Verbose -Message $deleteZoneMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq absent

    } # end found dns zone
    
    # Not found DNS Zone
    else
    {
        $testZoneMessage = $($LocalizedData.TestZoneMessage) -f 'absent', $Ensure
        Write-Verbose -Message $testZoneMessage

        if($Ensure -eq 'Present')
        {
            if($Apply)
            {
                $addingSecondaryZoneMessage = $LocalizedData.AddingSecondaryZoneMessage
                Write-Verbose -Message $addingSecondaryZoneMessage

                # Add the zone and start the transfer
                Add-DnsServerSecondaryZone -Name $Name -MasterServers $MasterServers -ZoneFile $Name
                Start-DnsServerZoneTransfer -Name $Name -FullTransfer
                
                $newSecondaryZoneMessage = $($LocalizedData.NewSecondaryZoneMessage) -f $Name
                Write-Verbose -Message $newSecondaryZoneMessage
            }
            else
            {
                return $false
            }
        } # end ensure -eq Present
        else
        {
            if(-not $Apply)
            {
                return $true
            }
        } # end ensure -eq Absent
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource

