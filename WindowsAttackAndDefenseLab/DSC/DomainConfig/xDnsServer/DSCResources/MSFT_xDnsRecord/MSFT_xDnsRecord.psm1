# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        GettingDnsRecordMessage   = Getting DNS record '{0}' ({1}) in zone '{2}'.
        CreatingDnsRecordMessage  = Creating DNS record '{0}' for target '{1}' in zone '{2}'.
        RemovingDnsRecordMessage  = Removing DNS record '{0}' for target '{1}' in zone '{2}'.
        NotDesiredPropertyMessage = DNS record property '{0}' is not correct. Expected '{1}', actual '{2}'
        InDesiredStateMessage     = DNS record '{0}' is in the desired state.
        NotInDesiredStateMessage  = DNS record '{0}' is NOT in the desired state.
'@
}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($LocalizedData.GettingDnsRecordMessage -f $Name, $Type, $Zone)
    $record = Get-DnsServerResourceRecord -ZoneName $Zone -Name $Name -ErrorAction SilentlyContinue
    
    if ($record -eq $null) 
    {
        return @{
            Name = $Name.HostName;
            Zone = $Zone;
            Target = $Target;
            Ensure = 'Absent';
        }
    }
    if ($Type -eq "CName") 
    {
        $recordData = ($record.RecordData.hostnamealias).TrimEnd('.')
    }
    if ($Type -eq "ARecord") 
    {
        $recordData = $record.RecordData.IPv4address.IPAddressToString
    }

    return @{
        Name = $record.HostName;
        Zone = $Zone;
        Target = $recordData;
        Ensure = 'Present';
    }
} #end function Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $DNSParameters = @{ Name = $Name; ZoneName = $Zone; } 

    if ($Ensure -eq 'Present')
    {
        if ($Type -eq "ARecord")
        {
            $DNSParameters.Add('A',$true)
            $DNSParameters.Add('IPv4Address',$target)
        }
        if ($Type -eq "CName")
        {
            $DNSParameters.Add('CName',$true)
            $DNSParameters.Add('HostNameAlias',$Target)
        }
        Write-Verbose -Message ($LocalizedData.CreatingDnsRecordMessage -f $Type, $Target, $Zone)
        Add-DnsServerResourceRecord @DNSParameters
    }
    elseif ($Ensure -eq 'Absent')
    {
        
        $DNSParameters.Add('Computername','localhost')
        $DNSParameters.Add('Force',$true)

        if ($Type -eq "ARecord")
        {
            $DNSParameters.Add('RRType','A')
        }
        if ($Type -eq "CName")
        {
            $DNSParameters.Add('RRType','CName')
        }
        Write-Verbose -Message ($LocalizedData.RemovingDnsRecordMessage -f $Type, $Target, $Zone)
        Remove-DnsServerResourceRecord @DNSParameters
    }
} #end function Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $result = @(Get-TargetResource @PSBoundParameters)
    if ($Ensure -ne $result.Ensure)
    {
        Write-Verbose -Message ($LocalizedData.NotDesiredPropertyMessage -f 'Ensure', $Ensure, $result.Ensure)
        Write-Verbose -Message ($LocalizedData.NotInDesiredStateMessage -f $Name)
        return $false
    }
    elseif ($Ensure -eq 'Present')
    {
        if ($result.Target -notcontains $Target)
        {
            $resultTargetString = $result.Target
            if ($resultTargetString -is [System.Array])
            {
                ## We have an array, create a single string for verbose output
                $resultTargetString = $result.Target -join ','
            }
            Write-Verbose -Message ($LocalizedData.NotDesiredPropertyMessage -f 'Target', $Target, $resultTargetString)
            Write-Verbose -Message ($LocalizedData.NotInDesiredStateMessage -f $Name)
            return $false
        }
    }
    Write-Verbose -Message ($LocalizedData.InDesiredStateMessage -f $Name)
    return $true
} #end function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
