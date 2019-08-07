<#PSScriptInfo
.VERSION 1.0.0
.GUID a18e0a9-2a4b-4406-939e-ac2bb7b6e917
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/xActiveDirectory/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/xActiveDirectory
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module xActiveDirectory

<#
    .DESCRIPTION
        This configuration will create an Active Directory computer account
        on the specified domain controller and in the specific organizational
        unit.
#>

Configuration AddComputerAccountSpecificPath_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainAdministratorCredential
    )

    Import-DscResource -ModuleName xActiveDirectory

    node localhost
    {
        xADComputer 'CreateComputerAccount'
        {
            DomainController              = 'DC01'
            ComputerName                  = 'SQL01'
            Path                          = 'OU=Servers,DC=contoso,DC=com'
            DomainAdministratorCredential = $DomainAdministratorCredential
        }
    }
}
