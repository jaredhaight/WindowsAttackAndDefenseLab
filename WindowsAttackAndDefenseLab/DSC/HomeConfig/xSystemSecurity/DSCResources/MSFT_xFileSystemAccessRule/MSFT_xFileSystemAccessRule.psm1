function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])] 
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $Identity,

        [Parameter(Mandatory = $false)]
        [String[]]
        [ValidateSet("ListDirectory",
                     "ReadData",
                     "WriteData",
                     "CreateFiles",
                     "CreateDirectories",
                     "AppendData",
                     "ReadExtendedAttributes",
                     "WriteExtendedAttributes",
                     "Traverse",
                     "ExecuteFile",
                     "DeleteSubdirectoriesAndFiles",
                     "ReadAttributes",
                     "WriteAttributes",
                     "Write",
                     "Delete",
                     "ReadPermissions",
                     "Read",
                     "ReadAndExecute",
                     "Modify",
                     "ChangePermissions",
                     "TakeOwnership",
                     "Synchronize",
                     "FullControl")]
        $Rights,

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )
    
    if ((Test-Path -Path $Path) -eq $false)
    {
        throw "Unable to get ACL for '$Path' as it does not exist"
    }

    $acl = Get-Acl -Path $Path
    $accessRules = $acl.Access

    $identityRule = $accessRules | Where-Object -FilterScript {
        $_.IdentityReference -eq $Identity
    } | Select-Object -First 1

    if ($null -eq $identityRule)
    {
        return @{
            Path = $Path
            Identity = $Identity
            Rights = @()
            Ensure = "Absent"
        }
    }
    return @{
        Path = $Path
        Identity = $Identity
        Rights = $identityRule.FileSystemRights.ToString() -split ", "
        Ensure = "Present"
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $Identity,

        [Parameter(Mandatory = $false)]
        [String[]]
        [ValidateSet("ListDirectory",
                     "ReadData",
                     "WriteData",
                     "CreateFiles",
                     "CreateDirectories",
                     "AppendData",
                     "ReadExtendedAttributes",
                     "WriteExtendedAttributes",
                     "Traverse",
                     "ExecuteFile",
                     "DeleteSubdirectoriesAndFiles",
                     "ReadAttributes",
                     "WriteAttributes",
                     "Write",
                     "Delete",
                     "ReadPermissions",
                     "Read",
                     "ReadAndExecute",
                     "Modify",
                     "ChangePermissions",
                     "TakeOwnership",
                     "Synchronize",
                     "FullControl")]
        $Rights,

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )

    if ((Test-Path -Path $Path) -eq $false)
    {
        throw "Unable to get ACL for '$Path' as it does not exist"
    }

    $acl = Get-Acl -Path $Path
    $accessRules = $acl.Access

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Setting access rules for $Identity on $Path"
        $newRights = [System.Security.AccessControl.FileSystemRights]$Rights
        $ar = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule `
                         -ArgumentList @(
                                $Identity, 
                                $newRights, 
                                "ContainerInherit,ObjectInherit", 
                                "None", 
                                "Allow")
        $acl.SetAccessRule($ar)

        Set-Acl -Path $Path -AclObject $acl

    }

    if ($Ensure -eq "Absent")
    {
        $identityRule = $accessRules | Where-Object -FilterScript {
            $_.IdentityReference -eq $Identity
        } | Select-Object -First 1

        if ($null -ne $identityRule)
        {
            Write-Verbose -Message "Removing access rules for $Identity on $Path"
            $acl.RemoveAccessRule($identityRule) | Out-Null
            Set-Acl -Path $Path -AclObject $acl
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])] 
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $Identity,

        [Parameter(Mandatory = $false)]
        [String[]]
        [ValidateSet("ListDirectory",
                     "ReadData",
                     "WriteData",
                     "CreateFiles",
                     "CreateDirectories",
                     "AppendData",
                     "ReadExtendedAttributes",
                     "WriteExtendedAttributes",
                     "Traverse",
                     "ExecuteFile",
                     "DeleteSubdirectoriesAndFiles",
                     "ReadAttributes",
                     "WriteAttributes",
                     "Write",
                     "Delete",
                     "ReadPermissions",
                     "Read",
                     "ReadAndExecute",
                     "Modify",
                     "ChangePermissions",
                     "TakeOwnership",
                     "Synchronize",
                     "FullControl")]
        $Rights,

        [Parameter(Mandatory = $false)]
        [String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) 
    {
        throw "Unable to determine current ACL values for '$Path'"
    }

    if ($CurrentValues.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Ensure property does not match"
        return $false
    }

    if ($Ensure -eq "Present")
    {
        $rightsCompare = Compare-Object -ReferenceObject $CurrentValues.Rights `
                                        -DifferenceObject $Rights
        if ($null -ne $rightsCompare)
        {
            Write-Verbose -Message "Rights property does not match"
            return $false
        }
    }

    return $true
}

Export-ModuleMember -Function *-TargetResource
