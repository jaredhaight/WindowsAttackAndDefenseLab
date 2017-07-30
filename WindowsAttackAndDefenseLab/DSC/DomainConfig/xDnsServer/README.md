[![Build status](https://ci.appveyor.com/api/projects/status/qqspiio117bgaieo/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xdnsserver/branch/master)

# xDnsServer

The **xDnsServer** DSC resources configure and manage a DNS server. They include **xDnsServerPrimaryZone**, **xDnsServerSecondaryZone**, **xDnsServerADZone**, **xDnsServerZoneTransfer** and **xDnsARecord**.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

* **xDnsServerForwarder** sets a DNS forwarder on a given DNS server.
* **xDnsServerADZone** sets an AD integrated zone on a given DNS server.
* **xDnsServerPrimaryZone** sets a standalone Primary zone on a given DNS server.
* **xDnsServerSecondaryZone** sets a Secondary zone on a given DNS server.
Secondary zones allow client machine in primary DNS zones to do DNS resolution of machines in the secondary DNS zone.
* **xDnsServerZoneTransfer** This resource allows a DNS Server zone data to be replicated to another DNS server.
* **xDnsRecord** This resource allows for the creation of IPv4 host (A) records or CNames against a specific zone on the DNS server

### xDnsServerForwarder

* **IsSingleInstance**: Specifies the resource is a single instance, the value must be 'Yes'
* **IPAddresses**: IP addresses of the forwarders

#### xDnsServerADZone

* **Name**: Name of the AD DNS zone
* **Ensure**: Whether the AD zone should be present or removed
* **DynamicUpdate**: AD zone dynamic DNS update option.
 * If not specified, defaults to 'Secure'.
 * Valid values include: { None | NonsecureAndSecure | Secure }
* **ReplicationScope**: AD zone replication scope option.
 * Valid values include: { Custom | Domain | Forest | Legacy }
* **DirectoryPartitionName**: Name of the directory partition on which to store the zone.
 * Use this parameter when the ReplicationScope parameter has a value of Custom.
* **ComputerName**: Specifies a DNS server.
 * If you do not specify this parameter, the command runs on the local system.
* **Credential**: Specifies the credential to use to create the AD zone.
 * If you do not specify this parameter, the command runs as the local system.

### xDnsServerPrimaryZone

* **Name**: Name of the primary DNS zone
* **ZoneFile**: Name of the primary DNS zone file.
 * If not specified, defaults to 'ZoneName.dns'.
* **Ensure**: Whether the primary zone should be present or removed
* **DynamicUpdate**: Primary zone dynamic DNS update option.
 * If not specified, defaults to 'None'.
 * Valid values include: { None | NonsecureAndSecure }

### xDnsServerSecondaryZone

* **Name**: Name of the secondary zone
* **MasterServers**: IP address or DNS name of the secondary DNS servers
* **Ensure**: Whether the secondary zone should be present or removed
* **Type**: Type of the DNS server zone

### xDnsServerZoneTransfer

* **Name**: Name of the DNS zone
* **Type**: Type of transfer allowed.
Values include: { None | Any | Named | Specific }
* **SecondaryServer**: IP address or DNS name of DNS servers where zone information can be transfered.

### xDnsARecord {Will be removed in a future release}
* **Name**: Name of the host
* **Zone**: The name of the zone to create the host record in
* **Target**: Target Hostname or IP Address {*Only Supports IPv4 in the current release*}
* **Ensure**: Whether the host record should be present or removed

### xDnsRecord
* **Name**: Name of the host
* **Zone**: The name of the zone to create the host record in
* **Target**: Target Hostname or IP Address {*Only Supports IPv4 in the current release*}
* **Type**: DNS Record Type.
Values include: { ARecord | CName }
* **Ensure**: Whether the host record should be present or removed


## Versions

### Unreleased

* Converted AppVeyor.yml to pull Pester from PSGallery instead of Chocolatey

### 1.7.0.0

* Unit tests updated to use standard unit test templates.
* MSFT_xDnsServerZoneTransfer: Added unit tests.
                               Updated to meet Style Guidelines.
* MSFT_xDnsARecord: Removed hard coding of Localhost computer name to eliminate PSSA rule violation.

### 1.6.0.0

* Added Resource xDnsServerForwarder.
* Updated README.md with documentation and examples for xDnsServerForwarder resource.
* Added Resource xDnsServerADZone that sets an AD integrated DNS zone.
* Updated README.md with documentation and examples for xDnsServerADZone resource.
* Fixed bug in xDnsRecord causing Test-TargetResource to fail with multiple (round-robin) entries.
* Updated README.md with example DNS round-robin configuration.

### 1.5.0.0

* Added Resource xDnsRecord with support for CNames.
This will replace xDnsARecord in a future release.
* Added **xDnsServerPrimaryZone** resource

### 1.4.0.0
* Added support for removing DNS A records

### 1.3.0.0

* Fix to retrieving settings for record data

### 1.2.0.0

* Removed UTF8 BOM from MOF schema

### 1.1

* Add **xDnsARecord** resource.

### 1.0

*   Initial release with the following resources
    * **xDnsServerSecondaryZone**
    * **xDnsServerZoneTransfer**

## Examples

### Setting DNS Forwarders

```powershell
configuration Sample_Set_Forwarders
{
    Import-DscResource -module xDnsServer
    xDnsServerForwarder SetForwarders
    {
    	IsSingleInstance = 'Yes'
        IPAddresses = '192.168.0.10','192.168.0.11'
    }
}
Sample_Set_Forwarders
```

### Removing All DNS Forwarders

```powershell
configuration Sample_Remove_All_Forwarders
{
    Import-DscResource -module xDnsServer
    xDnsServerForwarder RemoveAllForwarders
    {
        IsSingleInstance = 'Yes'
        IPAddresses = @()
    }
}
Sample_Remove_All_Forwarders

### Configuring an AD integrated Forward Lookup Zone

```powershell
configuration Sample_xDnsServerForwardADZone
{
    param
    (
        [pscredential]$Credential,
    )
    Import-DscResource -module xDnsServer
    xDnsServerADZone addForwardADZone
    {
        Name = 'MyDomainName.com'
        DynamicUpdate = 'Secure'
        ReplicationScope = 'Forest'
        ComputerName = 'MyDnsServer.MyDomain.com'
        Credential = $Credential
        Ensure = 'Present'
    }
}
Sample_xDnsServerForwardADZone -Credential (Get-Credential)
```

### Configuring an AD integrated Reverse Lookup Zone

```powershell
configuration Sample_xDnsServerReverseADZone
{
    Import-DscResource -module xDnsServer
    xDnsServerADZone addReverseADZone
    {
        Name = '1.168.192.in-addr.arpa'
        DynamicUpdate = 'Secure'
        ReplicationScope = 'Forest'
        Ensure = 'Present'
    }
}
Sample_xDnsServerReverseADZone
```

### Configuring a DNS Transfer Zone

```powershell
configuration Sample_xDnsServerZoneTransfer_TransferToAnyServer
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DnsZoneName,

        [Parameter(Mandatory)]
        [String]$TransferType
    )
    Import-DscResource -module xDnsServer
    xDnsServerZoneTransfer TransferToAnyServer
    {
        Name = $DnsZoneName
        Type = $TransferType
    }
}
Sample_xDnsServerZoneTransfer_TransferToAnyServer -DnsZoneName 'demo.contoso.com' -TransferType 'Any'
```

### Configuring a Primary Standalone DNS Zone

```powershell
configuration Sample_xDnsServerPrimaryZone
{
    param
    (
        [Parameter(Mandatory)]
        [String]$ZoneName,
        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$ZoneFile = "$ZoneName.dns",
        [Parameter()] [ValidateSet('None','NonsecureAndSecure')]
        [String]$DynamicUpdate = 'None'
    )

    Import-DscResource -module xDnsServer
    xDnsServerPrimaryZone addPrimaryZone
    {
        Ensure        = 'Present'
        Name          = $ZoneName
        ZoneFile      = $ZoneFile
        DynamicUpdate = $DynamicUpdate
    }
}
Sample_xDnsServerPrimaryZone -ZoneName 'demo.contoso.com' -DyanmicUpdate 'NonsecureAndSecure'
```

### Configuring a Secondary DNS Zone

```powershell
configuration Sample_xDnsServerSecondaryZone
{
    param
    (
        [Parameter(Mandatory)]
        [String]$ZoneName,
        [Parameter(Mandatory)]
        [String[]]$SecondaryDnsServer
    )

    Import-DscResource -module xDnsServer
    xDnsServerSecondaryZone sec
    {
        Ensure        = 'Present'
        Name          = $ZoneName
        MasterServers = $SecondaryDnsServer

    }
}
Sample_xDnsServerSecondaryZone -ZoneName 'demo.contoso.com' -SecondaryDnsServer '192.168.10.2'
```

### Adding a DNS ARecord

```powershell
configuration Sample_Arecord
{
    Import-DscResource -module xDnsServer
    xDnsRecord TestRecord
    {
        Name = "testArecord"
        Target = "192.168.0.123"
        Zone = "contoso.com"
	    Type = "ARecord"
        Ensure = "Present"
    }
}
Sample_Arecord
```

### Adding round-robin DNS ARecords

```powershell
configuration Sample_RoundRobin_Arecord
{
    Import-DscResource -module xDnsServer
    xDnsRecord TestRecord1
    {
        Name = "testArecord"
        Target = "192.168.0.123"
        Zone = "contoso.com"
	    Type = "ARecord"
        Ensure = "Present"
    }
    xDnsRecord TestRecord2
    {
        Name = "testArecord"
        Target = "192.168.0.124"
        Zone = "contoso.com"
	    Type = "ARecord"
        Ensure = "Present"
    }

}
Sample_RoundRobin_Arecord
```

### Adding a DNS CName

```powershell
configuration Sample_CName
{
    Import-DscResource -module xDnsServer
    xDnsRecord TestRecord
    {
        Name = "testCName"
        Target = "test.contoso.com"
        Zone = "contoso.com"
	    Type = "CName"
        Ensure = "Present"
    }
}
Sample_Crecord
```

### Removing a DNS A Record

```powershell
configuration Sample_Remove_Record
{
    Import-DscResource -module xDnsServer
    xDnsARecord RemoveTestRecord
    {
        Name = "testArecord"
        Target = "192.168.0.123"
        Zone = "contoso.com"
	    Type = "ARecord"
        Ensure = "Absent"
    }
}
Sample_Sample_Remove_Record
```
