<#PSScriptInfo
.VERSION 1.0.0
.GUID c5ba4d3d-72ec-4dfc-b1f9-ff1f4c45f845
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
        unit. After the account is create an Offline Domain Join Request file
        is created to the specified path.
#>

Configuration AddComputerAccountAndCreateODJRequest_Config
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
            ComputerName                  = 'NANO-200'
            Path                          = 'OU=Servers,DC=contoso,DC=com'
            RequestFile                   = 'D:\ODJFiles\NANO-200.txt'
            DomainAdministratorCredential = $DomainAdministratorCredential
        }
    }
}
