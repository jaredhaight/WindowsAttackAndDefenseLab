@{

# Version number of this module.
ModuleVersion = '1.6.0.0'

# ID used to uniquely identify this module
GUID = 'd75e53f2-47fc-4ee7-97af-8d257d3e0151'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2014 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This DSC Resources can easily set the System Time Zone.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Functions to export from this module
# FunctionsToExport = ''

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xTimeZone/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xTimeZone'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* Add support for Nano Server and WMF5.1 via Get-Timezone/Set-Timezone cmdlets.
* Minor changes to bring make resource ready for HQRM.
* Renamed and reworked functions in TimezoneHelper.psm1 to prevent conflicts with new built-in WMF5.1 Timezone Cmdlets.
* Fixed localization so that failback to en-US if culture specific language files not available.
* Moved code to init C'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}



