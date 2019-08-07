[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "PasswordAuthentication")]
param()

$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:localizationModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'xActiveDirectory.Common'
Import-Module -Name (Join-Path -Path $script:localizationModulePath -ChildPath 'xActiveDirectory.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_xADUser'

# Create a property map that maps the DSC resource parameters to the
# Active Directory user attributes.
$adPropertyMap = @(
    @{
        Parameter  = 'CommonName'
        ADProperty = 'cn'
    }
    @{
        Parameter = 'UserPrincipalName'
    }
    @{
        Parameter = 'DisplayName'
    }
    @{
        Parameter  = 'Path'
        ADProperty = 'distinguishedName'
    }
    @{
        Parameter = 'GivenName'
    }
    @{
        Parameter = 'Initials'
    }
    @{
        Parameter  = 'Surname'
        ADProperty = 'sn'
    }
    @{
        Parameter = 'Description'
    }
    @{
        Parameter = 'StreetAddress'
    }
    @{
        Parameter = 'POBox'
    }
    @{
        Parameter  = 'City'
        ADProperty = 'l'
    }
    @{
        Parameter  = 'State'
        ADProperty = 'st'
    }
    @{
        Parameter = 'PostalCode'
    }
    @{
        Parameter  = 'Country'
        ADProperty = 'c'
    }
    @{
        Parameter = 'Department'
    }
    @{
        Parameter = 'Division'
    }
    @{
        Parameter = 'Company'
    }
    @{
        Parameter  = 'Office'
        ADProperty = 'physicalDeliveryOfficeName'
    }
    @{
        Parameter  = 'JobTitle'
        ADProperty = 'title'
    }
    @{
        Parameter  = 'EmailAddress'
        ADProperty = 'mail'
    }
    @{
        Parameter = 'EmployeeID'
    }
    @{
        Parameter = 'EmployeeNumber'
    }
    @{
        Parameter = 'HomeDirectory'
    }
    @{
        Parameter = 'HomeDrive'
    }
    @{
        Parameter  = 'HomePage'
        ADProperty = 'wWWHomePage'
    }
    @{
        Parameter = 'ProfilePath'
    }
    @{
        Parameter  = 'LogonScript'
        ADProperty = 'scriptPath'
    }
    @{
        Parameter  = 'Notes'
        ADProperty = 'info'
    }
    @{
        Parameter  = 'OfficePhone'
        ADProperty = 'telephoneNumber'
    }
    @{
        Parameter  = 'MobilePhone'
        ADProperty = 'mobile'
    }
    @{
        Parameter  = 'Fax'
        ADProperty = 'facsimileTelephoneNumber'
    }
    @{
        Parameter = 'Pager'
    }
    @{
        Parameter = 'IPPhone'
    }
    @{
        Parameter = 'HomePhone'
    }
    @{
        Parameter = 'Enabled'
    }
    @{
        Parameter = 'Manager'
    }
    @{
         Parameter = 'Organization'
    }
    @{
        Parameter = 'OtherName'
    }
    @{
        Parameter          = 'PasswordNeverExpires'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'CannotChangePassword'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'ChangePasswordAtLogon'
        UseCmdletParameter = $true
        ADProperty         = 'pwdLastSet'
    }
    @{
        Parameter          = 'TrustedForDelegation'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'AccountNotDelegated'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'AllowReversiblePasswordEncryption'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'CompoundIdentitySupported'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'PasswordNotRequired'
        UseCmdletParameter = $true
    }
    @{
        Parameter          = 'SmartcardLogonRequired'
        UseCmdletParameter = $true
    }
    @{
        Parameter  = 'ServicePrincipalNames'
        ADProperty = 'ServicePrincipalName'
        Type       = 'Array'
    }
    @{
        Parameter = 'ProxyAddresses'
        Type      = 'Array'
    }
)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # Name of the domain where the user account is located (only used if password is managed)
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        # Specifies the Security Account Manager (SAM) account name of the user (ldapDisplayName 'sAMAccountName')
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        # Specifies a new password value for an account
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Password,

        # Specifies whether the user account is created or deleted
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        # Specifies the common name assigned to the user account (ldapDisplayName 'cn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $CommonName = $UserName,

        # Specifies the UPN assigned to the user account (ldapDisplayName 'userPrincipalName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $UserPrincipalName,

        # Specifies the display name of the object (ldapDisplayName 'displayName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DisplayName,

        # Specifies the X.500 path of the Organizational Unit (OU) or container where the new object is created
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Path,

        # Specifies the user's given name (ldapDisplayName 'givenName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $GivenName,

        # Specifies the initials that represent part of a user's name (ldapDisplayName 'initials')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Initials,

        # Specifies the user's last name or surname (ldapDisplayName 'sn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Surname,

        # Specifies a description of the object (ldapDisplayName 'description')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Description,

        # Specifies the user's street address (ldapDisplayName 'streetAddress')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $StreetAddress,

        # Specifies the user's post office box number (ldapDisplayName 'postOfficeBox')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $POBox,

        # Specifies the user's town or city (ldapDisplayName 'l')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $City,

        # Specifies the user's or Organizational Unit's state or province (ldapDisplayName 'st')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $State,

        # Specifies the user's postal code or zip code (ldapDisplayName 'postalCode')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $PostalCode,

        # Specifies the country or region code for the user's language of choice (ldapDisplayName 'c')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Country,

        # Specifies the user's department (ldapDisplayName 'department')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Department,

        # Specifies the user's division (ldapDisplayName 'division')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Division,

        # Specifies the user's company (ldapDisplayName 'company')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Company,

        # Specifies the location of the user's office or place of business (ldapDisplayName 'physicalDeliveryOfficeName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Office,

        # Specifies the user's title (ldapDisplayName 'title')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $JobTitle,

        # Specifies the user's e-mail address (ldapDisplayName 'mail')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmailAddress,

        # Specifies the user's employee ID (ldapDisplayName 'employeeID')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeID,

        # Specifies the user's employee number (ldapDisplayName 'employeeNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeNumber,

        # Specifies a user's home directory path (ldapDisplayName 'homeDirectory')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDirectory,

        # Specifies a drive that is associated with the UNC path defined by the HomeDirectory property (ldapDisplayName 'homeDrive')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDrive,

        # Specifies the URL of the home page of the object (ldapDisplayName 'wWWHomePage')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePage,

        # Specifies a path to the user's profile (ldapDisplayName 'profilePath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $ProfilePath,

        # Specifies a path to the user's log on script (ldapDisplayName 'scriptPath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonScript,

        # Specifies the notes attached to the user's account (ldapDisplayName 'info')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Notes,

        # Specifies the user's office telephone number (ldapDisplayName 'telephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OfficePhone,

        # Specifies the user's mobile phone number (ldapDisplayName 'mobile')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $MobilePhone,

        # Specifies the user's fax phone number (ldapDisplayName 'facsimileTelephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Fax,

        # Specifies the user's home telephone number (ldapDisplayName 'homePhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePhone,

        # Specifies the user's pager number (ldapDisplayName 'pager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Pager,

        # Specifies the user's IP telephony phone number (ldapDisplayName 'ipPhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $IPPhone,

        # Specifies the user's manager specified as a Distinguished Name (ldapDisplayName 'manager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Manager,

        # Specifies the computers that the user can access. (ldapDisplayName 'userWorkStations')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonWorkstations,

        # Specifies the user's organization (ldapDisplayName 'o')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Organization,

        # Specifies a name in addition to a user's given name and surname (ldaDisplayName 'middleName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OtherName,

        # Specifies if the account is enabled (default True)
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $Enabled = $true,

        # Specifies whether the account password can be changed
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CannotChangePassword,

        # Specifies whether the account password must be changed during the next logon attempt
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $ChangePasswordAtLogon,

        # Specifies whether the password of an account can expire
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverExpires,

        # Specifies whether an account is trusted for Kerberos delegation
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $TrustedForDelegation,

        # Indicates whether the security context of the user is delegated to a service.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AccountNotDelegated,

        # Indicates whether reversible password encryption is allowed for the account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AllowReversiblePasswordEncryption,

        # Specifies whether an account supports Kerberos service tickets which includes the authorization data for the user's device.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CompoundIdentitySupported,

        # Specifies whether the account requires a password. A password is not required for a new account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNotRequired,

        # Specifies whether a smart card is required to logon.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $SmartcardLogonRequired,

        # Specifies the Active Directory Domain Services instance to use to perform the task.
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DomainController,

        # Specifies the user account credentials to use to perform this task. Ideally this should just be called 'Credential' but is here for backwards compatibility
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $DomainAdministratorCredential,

        # Specifies the authentication context type when testing user passwords #61
        [Parameter()]
        [ValidateSet('Default', 'Negotiate')]
        [System.String]
        $PasswordAuthentication = 'Default',

        # Specifies whether an existing user's password should be reset (default $false).
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverResets = $false,

        # Try to restore the organizational unit from the recycle bin before creating a new one.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $RestoreFromRecycleBin,

        # Specifies the service principal names registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ServicePrincipalNames,

        # Specifies the Proxy Addresses registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ProxyAddresses
    )

    Assert-Module -ModuleName 'ActiveDirectory'

    try
    {
        $adCommonParameters = Get-ADCommonParameters @PSBoundParameters

        $adProperties = @()

        # Create an array of the AD propertie names to retrieve from the property map
        foreach ($property in $adPropertyMap)
        {
            if ($property.ADProperty)
            {
                $adProperties += $property.ADProperty
            }
            else
            {
                $adProperties += $property.Parameter
            }
        }

        Write-Verbose -Message ($script:localizedData.RetrievingADUser -f $UserName, $DomainName)

        $adUser = Get-ADUser @adCommonParameters -Properties $adProperties

        Write-Verbose -Message ($script:localizedData.ADUserIsPresent -f $UserName, $DomainName)

        $Ensure = 'Present'
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        Write-Verbose -Message ($script:localizedData.ADUserNotPresent -f $UserName, $DomainName)

        $Ensure = 'Absent'
    }
    catch
    {
        $errorMessage = $script:localizedData.RetrievingADUserError -f $UserName, $DomainName
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    $targetResource = @{
        DomainName        = $DomainName
        Password          = $Password
        UserName          = $UserName
        DistinguishedName = $adUser.DistinguishedName; # Read-only property
        Ensure            = $Ensure
        DomainController  = $DomainController
    }

    # Retrieve each property from the ADPropertyMap and add to the hashtable
    foreach ($property in $adPropertyMap)
    {
        $parameter = $property.Parameter
        if ($parameter -eq 'Path')
        {
            # The path returned is not the parent container
            if (-not [System.String]::IsNullOrEmpty($adUser.DistinguishedName))
            {
                $targetResource['Path'] = Get-ADObjectParentDN -DN $adUser.DistinguishedName
            }
        }
        elseif (($parameter) -eq 'ChangePasswordAtLogon')
        {
            if ($adUser.pwdlastset -eq 0)
            {
                $targetResource['ChangePasswordAtLogon'] = $true
            }
            else
            {
                $targetResource['ChangePasswordAtLogon'] = $false
            }
        }
        elseif ($property.ADProperty)
        {
            # The AD property name is different to the function parameter to use this
            $aDProperty = $property.ADProperty
            if ($property.Type -eq 'Array')
            {
                $targetResource[$parameter] = [System.String[]] $adUser.$aDProperty
            }
            else
            {
                $targetResource[$parameter] = $adUser.$aDProperty
            }
        }
        else
        {
            # The AD property name matches the function parameter
            if ($property.Type -eq 'Array')
            {
                $targetResource[$Parameter] = [System.String[]] $adUser.$parameter
            }
            else
            {
                $targetResource[$Parameter] = $adUser.$parameter
            }
        }
    }

    return $targetResource
} #end function Get-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # Name of the domain where the user account is located (only used if password is managed)
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        # Specifies the Security Account Manager (SAM) account name of the user (ldapDisplayName 'sAMAccountName')
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        # Specifies a new password value for an account
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Password,

        # Specifies whether the user account is created or deleted
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        # Specifies the common name assigned to the user account (ldapDisplayName 'cn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $CommonName = $UserName,

        # Specifies the UPN assigned to the user account (ldapDisplayName 'userPrincipalName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $UserPrincipalName,

        # Specifies the display name of the object (ldapDisplayName 'displayName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DisplayName,

        # Specifies the X.500 path of the Organizational Unit (OU) or container where the new object is created
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Path,

        # Specifies the user's given name (ldapDisplayName 'givenName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $GivenName,

        # Specifies the initials that represent part of a user's name (ldapDisplayName 'initials')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Initials,

        # Specifies the user's last name or surname (ldapDisplayName 'sn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Surname,

        # Specifies a description of the object (ldapDisplayName 'description')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Description,

        # Specifies the user's street address (ldapDisplayName 'streetAddress')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $StreetAddress,

        # Specifies the user's post office box number (ldapDisplayName 'postOfficeBox')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $POBox,

        # Specifies the user's town or city (ldapDisplayName 'l')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $City,

        # Specifies the user's or Organizational Unit's state or province (ldapDisplayName 'st')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $State,

        # Specifies the user's postal code or zip code (ldapDisplayName 'postalCode')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $PostalCode,

        # Specifies the country or region code for the user's language of choice (ldapDisplayName 'c')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Country,

        # Specifies the user's department (ldapDisplayName 'department')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Department,

        # Specifies the user's division (ldapDisplayName 'division')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Division,

        # Specifies the user's company (ldapDisplayName 'company')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Company,

        # Specifies the location of the user's office or place of business (ldapDisplayName 'physicalDeliveryOfficeName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Office,

        # Specifies the user's title (ldapDisplayName 'title')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $JobTitle,

        # Specifies the user's e-mail address (ldapDisplayName 'mail')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmailAddress,

        # Specifies the user's employee ID (ldapDisplayName 'employeeID')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeID,

        # Specifies the user's employee number (ldapDisplayName 'employeeNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeNumber,

        # Specifies a user's home directory path (ldapDisplayName 'homeDirectory')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDirectory,

        # Specifies a drive that is associated with the UNC path defined by the HomeDirectory property (ldapDisplayName 'homeDrive')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDrive,

        # Specifies the URL of the home page of the object (ldapDisplayName 'wWWHomePage')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePage,

        # Specifies a path to the user's profile (ldapDisplayName 'profilePath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $ProfilePath,

        # Specifies a path to the user's log on script (ldapDisplayName 'scriptPath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonScript,

        # Specifies the notes attached to the user's account (ldapDisplayName 'info')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Notes,

        # Specifies the user's office telephone number (ldapDisplayName 'telephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OfficePhone,

        # Specifies the user's mobile phone number (ldapDisplayName 'mobile')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $MobilePhone,

        # Specifies the user's fax phone number (ldapDisplayName 'facsimileTelephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Fax,

        # Specifies the user's home telephone number (ldapDisplayName 'homePhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePhone,

        # Specifies the user's pager number (ldapDisplayName 'pager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Pager,

        # Specifies the user's IP telephony phone number (ldapDisplayName 'ipPhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $IPPhone,

        # Specifies the user's manager specified as a Distinguished Name (ldapDisplayName 'manager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Manager,

        # Specifies the computers that the user can access. (ldapDisplayName 'userWorkStations')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonWorkstations,

        # Specifies the user's organization (ldapDisplayName 'o')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Organization,

        # Specifies a name in addition to a user's given name and surname (ldaDisplayName 'middleName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OtherName,

        # Specifies if the account is enabled (default True)
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $Enabled = $true,

        # Specifies whether the account password can be changed
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CannotChangePassword,

        # Specifies whether the account password must be changed during the next logon attempt
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $ChangePasswordAtLogon,

        # Specifies whether the password of an account can expire
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverExpires,

        # Specifies whether an account is trusted for Kerberos delegation
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $TrustedForDelegation,

        # Indicates whether the security context of the user is delegated to a service.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AccountNotDelegated,

        # Indicates whether reversible password encryption is allowed for the account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AllowReversiblePasswordEncryption,

        # Specifies whether an account supports Kerberos service tickets which includes the authorization data for the user's device.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CompoundIdentitySupported,

        # Specifies whether the account requires a password. A password is not required for a new account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNotRequired,

        # Specifies whether a smart card is required to logon.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $SmartcardLogonRequired,

        # Specifies the Active Directory Domain Services instance to use to perform the task.
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DomainController,

        # Specifies the user account credentials to use to perform this task. Ideally this should just be called 'Credential' but is here for backwards compatibility
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $DomainAdministratorCredential,

        # Specifies the authentication context type when testing user passwords #61
        [Parameter()]
        [ValidateSet('Default', 'Negotiate')]
        [System.String]
        $PasswordAuthentication = 'Default',

        # Specifies whether an existing user's password should be reset (default $false).
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverResets = $false,

        # Try to restore the organizational unit from the recycle bin before creating a new one.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $RestoreFromRecycleBin,

        # Specifies the service principal names registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ServicePrincipalNames,

        # Specifies the Proxy Addresses registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ProxyAddresses
    )

    Assert-Parameters @PSBoundParameters

    $targetResource = Get-TargetResource @PSBoundParameters

    $isCompliant = $true

    if ($Ensure -eq 'Absent')
    {
        if ($targetResource.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.ADUserNotDesiredPropertyState -f 'Ensure', $PSBoundParameters.Ensure, $targetResource.Ensure)
            $isCompliant = $false
        }
    }
    else
    {
        # Add common name, ensure and enabled as they may not be explicitly passed and we want to enumerate them
        $PSBoundParameters['Ensure'] = $Ensure
        $PSBoundParameters['Enabled'] = $Enabled

        foreach ($parameter in $PSBoundParameters.Keys)
        {
            if ($parameter -eq 'Password' -and $PasswordNeverResets -eq $false)
            {
                $testPasswordParams = @{
                    Username               = $UserName
                    Password               = $Password
                    DomainName             = $DomainName
                    PasswordAuthentication = $PasswordAuthentication
                }

                if ($DomainAdministratorCredential)
                {
                    $testPasswordParams['DomainAdministratorCredential'] = $DomainAdministratorCredential
                }

                if (-not (Test-Password @testPasswordParams))
                {
                    Write-Verbose -Message ($script:localizedData.ADUserNotDesiredPropertyState -f 'Password', '<Password>', '<Password>')
                    $isCompliant = $false
                }
            }
            # Only check properties that are returned by Get-TargetResource
            elseif ($targetResource.ContainsKey($parameter))
            {
                # This check is required to be able to explicitly remove values with an empty string, if required
                if (([System.String]::IsNullOrEmpty($PSBoundParameters.$parameter)) -and ([System.String]::IsNullOrEmpty($targetResource.$parameter)))
                {
                    # Both values are null/empty and therefore we are compliant
                }
                elseif (($null -ne $PSBoundParameters.$parameter -and $null -eq $targetResource.$parameter) -or
                        ($null -eq $PSBoundParameters.$parameter -and $null -ne $targetResource.$parameter) -or
                        (Compare-Object -ReferenceObject $PSBoundParameters.$parameter -DifferenceObject $targetResource.$parameter))
                {
                    Write-Verbose -Message ($script:localizedData.ADUserNotDesiredPropertyState -f $parameter,
                        ($PSBoundParameters.$parameter -join '; '), ($targetResource.$parameter -join '; '))
                    $isCompliant = $false
                }
            }
        } #end foreach PSBoundParameter
    }

    return $isCompliant
} #end function Test-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        # Name of the domain where the user account is located (only used if password is managed)
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        # Specifies the Security Account Manager (SAM) account name of the user (ldapDisplayName 'sAMAccountName')
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        # Specifies a new password value for an account
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Password,

        # Specifies whether the user account is created or deleted
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        # Specifies the common name assigned to the user account (ldapDisplayName 'cn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $CommonName = $UserName,

        # Specifies the UPN assigned to the user account (ldapDisplayName 'userPrincipalName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $UserPrincipalName,

        # Specifies the display name of the object (ldapDisplayName 'displayName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DisplayName,

        # Specifies the X.500 path of the Organizational Unit (OU) or container where the new object is created
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Path,

        # Specifies the user's given name (ldapDisplayName 'givenName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $GivenName,

        # Specifies the initials that represent part of a user's name (ldapDisplayName 'initials')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Initials,

        # Specifies the user's last name or surname (ldapDisplayName 'sn')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Surname,

        # Specifies a description of the object (ldapDisplayName 'description')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Description,

        # Specifies the user's street address (ldapDisplayName 'streetAddress')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $StreetAddress,

        # Specifies the user's post office box number (ldapDisplayName 'postOfficeBox')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $POBox,

        # Specifies the user's town or city (ldapDisplayName 'l')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $City,

        # Specifies the user's or Organizational Unit's state or province (ldapDisplayName 'st')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $State,

        # Specifies the user's postal code or zip code (ldapDisplayName 'postalCode')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $PostalCode,

        # Specifies the country or region code for the user's language of choice (ldapDisplayName 'c')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Country,

        # Specifies the user's department (ldapDisplayName 'department')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Department,

        # Specifies the user's division (ldapDisplayName 'division')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Division,

        # Specifies the user's company (ldapDisplayName 'company')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Company,

        # Specifies the location of the user's office or place of business (ldapDisplayName 'physicalDeliveryOfficeName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Office,

        # Specifies the user's title (ldapDisplayName 'title')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $JobTitle,

        # Specifies the user's e-mail address (ldapDisplayName 'mail')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmailAddress,

        # Specifies the user's employee ID (ldapDisplayName 'employeeID')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeID,

        # Specifies the user's employee number (ldapDisplayName 'employeeNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $EmployeeNumber,

        # Specifies a user's home directory path (ldapDisplayName 'homeDirectory')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDirectory,

        # Specifies a drive that is associated with the UNC path defined by the HomeDirectory property (ldapDisplayName 'homeDrive')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomeDrive,

        # Specifies the URL of the home page of the object (ldapDisplayName 'wWWHomePage')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePage,

        # Specifies a path to the user's profile (ldapDisplayName 'profilePath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $ProfilePath,

        # Specifies a path to the user's log on script (ldapDisplayName 'scriptPath')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonScript,

        # Specifies the notes attached to the user's account (ldapDisplayName 'info')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Notes,

        # Specifies the user's office telephone number (ldapDisplayName 'telephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OfficePhone,

        # Specifies the user's mobile phone number (ldapDisplayName 'mobile')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $MobilePhone,

        # Specifies the user's fax phone number (ldapDisplayName 'facsimileTelephoneNumber')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Fax,

        # Specifies the user's home telephone number (ldapDisplayName 'homePhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $HomePhone,

        # Specifies the user's pager number (ldapDisplayName 'pager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Pager,

        # Specifies the user's IP telephony phone number (ldapDisplayName 'ipPhone')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $IPPhone,

        # Specifies the user's manager specified as a Distinguished Name (ldapDisplayName 'manager')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Manager,

        # Specifies the computers that the user can access. (ldapDisplayName 'userWorkStations')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $LogonWorkstations,

        # Specifies the user's organization (ldapDisplayName 'o')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $Organization,

        # Specifies a name in addition to a user's given name and surname (ldaDisplayName 'middleName')
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $OtherName,

        # Specifies if the account is enabled (default True)
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $Enabled = $true,

        # Specifies whether the account password can be changed
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CannotChangePassword,

        # Specifies whether the account password must be changed during the next logon attempt
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $ChangePasswordAtLogon,

        # Specifies whether the password of an account can expire
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverExpires,

        # Specifies whether an account is trusted for Kerberos delegation
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $TrustedForDelegation,

        # Indicates whether the security context of the user is delegated to a service.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AccountNotDelegated,

        # Indicates whether reversible password encryption is allowed for the account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $AllowReversiblePasswordEncryption,

        # Specifies whether an account supports Kerberos service tickets which includes the authorization data for the user's device.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $CompoundIdentitySupported,

        # Specifies whether the account requires a password. A password is not required for a new account.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNotRequired,

        # Specifies whether a smart card is required to logon.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $SmartcardLogonRequired,

        # Specifies the Active Directory Domain Services instance to use to perform the task.
        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $DomainController,

        # Specifies the user account credentials to use to perform this task. Ideally this should just be called 'Credential' but is here for backwards compatibility
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $DomainAdministratorCredential,

        # Specifies the authentication context type when testing user passwords #61
        [Parameter()]
        [ValidateSet('Default', 'Negotiate')]
        [System.String]
        $PasswordAuthentication = 'Default',

        # Specifies whether an existing user's password should be reset (default $false).
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverResets = $false,

        # Try to restore the organizational unit from the recycle bin before creating a new one.
        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $RestoreFromRecycleBin,

        # Specifies the service principal names registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ServicePrincipalNames,

        # Specifies the Proxy Addresses registered on the user account
        [Parameter()]
        [ValidateNotNull()]
        [System.String[]]
        $ProxyAddresses
    )

    Assert-Parameters @PSBoundParameters

    $targetResource = Get-TargetResource @PSBoundParameters

    # Add common name, ensure and enabled as they may not be explicitly passed
    $PSBoundParameters['Ensure'] = $Ensure
    $PSBoundParameters['Enabled'] = $Enabled

    if ($Ensure -eq 'Present')
    {
        if ($targetResource.Ensure -eq 'Absent')
        {
            # Try to restore account if it exists
            if ($RestoreFromRecycleBin)
            {
                Write-Verbose -Message ($script:localizedData.RestoringUser -f $UserName)
                $restoreParams = Get-ADCommonParameters @PSBoundParameters
                $restorationSuccessful = Restore-ADCommonObject @restoreParams -ObjectClass User -ErrorAction Stop
            }

            if (-not $RestoreFromRecycleBin -or ($RestoreFromRecycleBin -and -not $restorationSuccessful))
            {
                # User does not exist and needs creating
                $newADUserParams = Get-ADCommonParameters @PSBoundParameters -UseNameParameter

                if ($PSBoundParameters.ContainsKey('Path'))
                {
                    $newADUserParams['Path'] = $Path
                }

                # Populate the AccountPassword parameter of New-ADUser if password declared
                if ($PSBoundParameters.ContainsKey('Password'))
                {
                    $newADUserParams['AccountPassword'] = $Password.Password
                }

                Write-Verbose -Message ($script:localizedData.AddingADUser -f $UserName)

                New-ADUser @newADUserParams -SamAccountName $UserName

                # Now retrieve the newly created user
                $targetResource = Get-TargetResource @PSBoundParameters
            }
        }

        $setADUserParams = Get-ADCommonParameters @PSBoundParameters
        $replaceUserProperties = @{ }
        $clearUserProperties = @()

        foreach ($parameter in $PSBoundParameters.Keys)
        {
            # Only check/action properties specified/declared parameters that match one of the function's
            # parameters. This will ignore common parameters such as -Verbose etc.
            if ($targetResource.ContainsKey($parameter))
            {
                $adProperty = $adPropertyMap | Where-Object -FilterScript { $_.Parameter -eq $parameter }
                if ($parameter -eq 'Path' -and ($PSBoundParameters.Path -ne $targetResource.Path))
                {
                    # Cannot move users by updating the DistinguishedName property
                    $adCommonParameters = Get-ADCommonParameters @PSBoundParameters

                    # Using the SamAccountName for identity with Move-ADObject does not work, use the DN instead
                    $adCommonParameters['Identity'] = $targetResource.DistinguishedName

                    Write-Verbose -Message ($script:localizedData.MovingADUser -f $targetResource.Path, $PSBoundParameters.Path)

                    Move-ADObject @adCommonParameters -TargetPath $PSBoundParameters.Path
                }
                elseif ($parameter -eq 'CommonName' -and ($PSBoundParameters.CommonName -ne $targetResource.CommonName))
                {
                    # Cannot rename users by updating the CN property directly
                    $adCommonParameters = Get-ADCommonParameters @PSBoundParameters

                    # Using the SamAccountName for identity with Rename-ADObject does not work, use the DN instead
                    $adCommonParameters['Identity'] = $targetResource.DistinguishedName

                    Write-Verbose -Message ($script:localizedData.RenamingADUser -f $targetResource.CommonName, $PSBoundParameters.CommonName)

                    Rename-ADObject @adCommonParameters -NewName $PSBoundParameters.CommonName
                }
                elseif ($parameter -eq 'Password' -and $PasswordNeverResets -eq $false)
                {
                    $adCommonParameters = Get-ADCommonParameters @PSBoundParameters
                    $testPasswordParams = @{
                        Username               = $UserName
                        Password               = $Password
                        DomainName             = $DomainName
                        PasswordAuthentication = $PasswordAuthentication
                    }

                    if ($DomainAdministratorCredential)
                    {
                        $testPasswordParams['DomainAdministratorCredential'] = $DomainAdministratorCredential
                    }

                    if (-not (Test-Password @testPasswordParams))
                    {
                        Write-Verbose -Message ($script:localizedData.SettingADUserPassword -f $UserName)

                        Set-ADAccountPassword @adCommonParameters -Reset -NewPassword $Password.Password
                    }
                }
                elseif ($parameter -eq 'Enabled' -and ($PSBoundParameters.$parameter -ne $targetResource.$parameter))
                {
                    <#
                        We cannot enable/disable an account with -Add or -Replace parameters, but inform that
                        we will change this as it is out of compliance (it always gets set anyway).
                    #>
                    Write-Verbose -Message ($script:localizedData.UpdatingADUserProperty -f $parameter, $PSBoundParameters.$parameter)
                }
                # Use Compare-Object to allow comparison of string and array parameters
                elseif (($null -ne $PSBoundParameters.$parameter -and $null -eq $targetResource.$parameter) -or
                        ($null -eq $PSBoundParameters.$parameter -and $null -ne $targetResource.$parameter) -or
                        (Compare-Object -ReferenceObject $PSBoundParameters.$parameter -DifferenceObject $targetResource.$parameter))
                {
                    # Find the associated AD property
                    $adProperty = $adPropertyMap |
                        Where-Object -FilterScript { $_.Parameter -eq $parameter }

                    if ([System.String]::IsNullOrEmpty($adProperty))
                    {
                        # We can't do anything is an empty AD property!
                    }
                    else
                    {
                        if ([System.String]::IsNullOrEmpty($PSBoundParameters.$parameter) -and (-not ([System.String]::IsNullOrEmpty($targetResource.$parameter))))
                        {
                            # We are clearing the existing value
                            Write-Verbose -Message ($script:localizedData.ClearingADUserProperty -f $parameter)
                            if ($adProperty.UseCmdletParameter -eq $true)
                            {
                                # We need to pass the parameter explicitly to Set-ADUser, not via -Clear
                                $setADUserParams[$adProperty.Parameter] = $PSBoundParameters.$parameter
                            }
                            elseif ([System.String]::IsNullOrEmpty($adProperty.ADProperty))
                            {
                                $clearUserProperties += $adProperty.Parameter
                            }
                            else
                            {
                                $clearUserProperties += $adProperty.ADProperty
                            }
                        } #end if clear existing value
                        else
                        {
                            # We are replacing the existing value
                            Write-Verbose -Message ($script:localizedData.UpdatingADUserProperty -f $parameter, ($PSBoundParameters.$parameter -join ','))

                            if ($adProperty.UseCmdletParameter -eq $true)
                            {
                                # We need to pass the parameter explicitly to Set-ADUser, not via -Replace
                                $setADUserParams[$adProperty.Parameter] = $PSBoundParameters.$parameter
                            }
                            elseif ([System.String]::IsNullOrEmpty($adProperty.ADProperty))
                            {
                                $replaceUserProperties[$adProperty.Parameter] = $PSBoundParameters.$parameter
                            }
                            else
                            {
                                $replaceUserProperties[$adProperty.ADProperty] = $PSBoundParameters.$parameter
                            }
                        }
                    } #end if replace existing value
                }

            } #end if TargetResource parameter
        } #end foreach PSBoundParameter

        # Only pass -Clear and/or -Replace if we have something to set/change
        if ($replaceUserProperties.Count -gt 0)
        {
            $setADUserParams['Replace'] = $replaceUserProperties
        }

        if ($clearUserProperties.Count -gt 0)
        {
            $setADUserParams['Clear'] = $clearUserProperties;
        }

        Write-Verbose -Message ($script:localizedData.UpdatingADUser -f $UserName)

        [ref] $null = Set-ADUser @setADUserParams -Enabled $Enabled
    }
    elseif (($Ensure -eq 'Absent') -and ($targetResource.Ensure -eq 'Present'))
    {
        # User exists and needs removing
        Write-Verbose ($script:localizedData.RemovingADUser -f $UserName)

        $adCommonParameters = Get-ADCommonParameters @PSBoundParameters

        [ref] $null = Remove-ADUser @adCommonParameters -Confirm:$false
    }

} #end function Set-TargetResource

# Internal function to validate unsupported options/configurations
function Assert-Parameters
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $Enabled = $true,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $ChangePasswordAtLogon,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $PasswordNeverExpires,

        [Parameter(ValueFromRemainingArguments)]
        $IgnoredArguments
    )

    # We cannot test/set passwords on disabled AD accounts
    if (($PSBoundParameters.ContainsKey('Password')) -and ($Enabled -eq $false))
    {
        $throwInvalidArgumentErrorParams = @{
            ErrorId      = 'xADUser_DisabledAccountPasswordConflict'
            ErrorMessage = $script:localizedData.PasswordParameterConflictError -f 'Enabled', $false, 'Password'
        }

        ThrowInvalidArgumentError @throwInvalidArgumentErrorParams
    }

    # ChangePasswordAtLogon cannot be set for an account that also has PasswordNeverExpires set
    if ($PSBoundParameters.ContainsKey('ChangePasswordAtLogon') -and $PSBoundParameters['ChangePasswordAtLogon'] -eq $true -and
        $PSBoundParameters.ContainsKey('PasswordNeverExpires') -and $PSBoundParameters['PasswordNeverExpires'] -eq $true)
    {
        $throwInvalidArgumentErrorParams = @{
            ErrorId      = 'xADUser_ChangePasswordParameterConflict'
            ErrorMessage = $script:localizedData.ChangePasswordParameterConflictError
        }
        ThrowInvalidArgumentError @throwInvalidArgumentErrorParams
    }

} #end function Assert-Parameters

# Internal function to test the validity of a user's password.
function Test-Password
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Password,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $DomainAdministratorCredential,

        # Specifies the authentication context type when testing user passwords #61
        [Parameter(Mandatory = $true)]
        [ValidateSet('Default', 'Negotiate')]
        [System.String]
        $PasswordAuthentication
    )

    Write-Verbose -Message ($script:localizedData.CreatingADDomainConnection -f $DomainName)

    Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'

    if ($DomainAdministratorCredential)
    {
        $principalContext = New-Object -TypeName 'System.DirectoryServices.AccountManagement.PrincipalContext' -ArgumentList @(
            [System.DirectoryServices.AccountManagement.ContextType]::Domain,
            $DomainName,
            $DomainAdministratorCredential.UserName,
            $DomainAdministratorCredential.GetNetworkCredential().Password
        )
    }
    else
    {
        $principalContext = New-Object -TypeName 'System.DirectoryServices.AccountManagement.PrincipalContext' -ArgumentList @(
            [System.DirectoryServices.AccountManagement.ContextType]::Domain,
            $DomainName,
            $null,
            $null
        )
    }

    Write-Verbose -Message ($script:localizedData.CheckingADUserPassword -f $UserName)

    if ($PasswordAuthentication -eq 'Negotiate')
    {
        return $principalContext.ValidateCredentials(
            $UserName,
            $Password.GetNetworkCredential().Password,
            [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate -bor
            [System.DirectoryServices.AccountManagement.ContextOptions]::Signing -bor
            [System.DirectoryServices.AccountManagement.ContextOptions]::Sealing
        )
    }
    else
    {
        # Use default authentication context
        return $principalContext.ValidateCredentials(
            $UserName,
            $Password.GetNetworkCredential().Password
        )
    }
} #end function Test-Password

Export-ModuleMember -Function *-TargetResource
