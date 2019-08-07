[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

$script:dscModuleName = 'xActiveDirectory'
$script:dscResourceName = 'MSFT_xADOrganizationalUnit'

#region HEADER

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        function Get-ADOrganizationalUnit
        {
            param
            (
                $Name
            )
        }

        function Set-ADOrganizationalUnit
        {
            param
            (
                $Identity,
                $Credential
            )
        }

        function Remove-ADOrganizationalUnit
        {
            param
            (
                $Name,
                $Credential
            )
        }

        function New-ADOrganizationalUnit
        {
            param
            (
                $Name,
                $Credential
            )
        }

        $testCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList @(
            'DummyUser',
            (ConvertTo-SecureString -String 'DummyPassword' -AsPlainText -Force)
        )

        $testPresentParams = @{
            Name = 'TestOU'
            Path = 'OU=Fake,DC=contoso,DC=com'
            Description = 'Test AD OU description'
            Ensure = 'Present'
        }

        $testAbsentParams = $testPresentParams.Clone()
        $testAbsentParams['Ensure'] = 'Absent'

        $protectedFakeAdOu = @{
            Name = $testPresentParams.Name
            ProtectedFromAccidentalDeletion = $true
            Description = $testPresentParams.Description
        }

        #region Function Get-TargetResource
        Describe 'xADOrganizationalUnit\Get-TargetResource' {
            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource -is [System.Collections.Hashtable] | Should -Be $true
            }

            It 'Returns "Ensure" = "Present" when OU exists' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource.Ensure | Should -Be 'Present'
            }

            It 'Returns "Ensure" = "Absent" when OU does not exist' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit
                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource.Ensure | Should -Be 'Absent'
            }

            It 'Returns "ProtectedFromAccidentalDeletion" = "$true" when OU is protected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource.ProtectedFromAccidentalDeletion | Should -Be $true
            }

            It 'Returns "ProtectedFromAccidentalDeletion" = "$false" when OU is not protected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                    $unprotectedFakeAdOu = $protectedFakeAdOu.Clone()
                    $unprotectedFakeAdOu['ProtectedFromAccidentalDeletion'] = $false
                    return [PSCustomObject] $unprotectedFakeAdOu
                }
                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource.ProtectedFromAccidentalDeletion | Should -Be $false
            }

            It 'Returns an empty description' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                    $noDescriptionFakeAdOu = $protectedFakeAdOu.Clone()
                    $noDescriptionFakeAdOu['Description'] = ''
                    return [PSCustomObject] $noDescriptionFakeAdOu
                }

                $targetResource = Get-TargetResource -Name $testPresentParams.Name -Path $testPresentParams.Path

                $targetResource.Description | Should -BeNullOrEmpty
            }

        }
        #endregion

        #region Function Test-TargetResource
        Describe 'xADOrganizationalUnit\Test-TargetResource' {
            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $targetResource = Test-TargetResource @testPresentParams

                $targetResource -is [System.Boolean] | Should -Be $true
            }

            It 'Fails when OU does not exist and "Ensure" = "Present"' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit

                Test-TargetResource @testPresentParams | Should -Be $false
            }

            It 'Fails when OU does exist and "Ensure" = "Absent"' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }

                Test-TargetResource @testAbsentParams | Should -Be $false
            }

            It 'Fails when OU does exist but "Description" is incorrect' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $testDescriptionParams = $testPresentParams.Clone()
                $testDescriptionParams['Description'] = 'Wrong description'

                Test-TargetResource @testDescriptionParams | Should -Be $false
            }

            It 'Fails when OU does exist but "ProtectedFromAccidentalDeletion" is incorrect' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $testProtectedFromAccidentalDeletionParams = $testPresentParams.Clone()
                $testProtectedFromAccidentalDeletionParams['ProtectedFromAccidentalDeletion'] = $false

                Test-TargetResource @testProtectedFromAccidentalDeletionParams | Should -Be $false
            }

            It 'Passes when OU does exist, "Ensure" = "Present" and all properties are correct' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }

                Test-TargetResource @testPresentParams | Should -Be $true
            }

            It 'Passes when OU does not exist and "Ensure" = "Absent"' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit

                Test-TargetResource @testAbsentParams | Should -Be $true
            }

            It 'Passes when no OU description is specified with existing OU description' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                $testEmptyDescriptionParams = $testPresentParams.Clone()
                $testEmptyDescriptionParams['Description'] = ''

                Test-TargetResource @testEmptyDescriptionParams | Should -Be $true
            }

        }
        #endregion

        #region Function Set-TargetResource
        Describe 'xADOrganizationalUnit\Set-TargetResource' {
            It 'Calls "New-ADOrganizationalUnit" when "Ensure" = "Present" and OU does not exist' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit
                Mock -CommandName New-ADOrganizationalUnit -ParameterFilter { $Name -eq $testPresentParams.Name }

                Set-TargetResource @testPresentParams
                Assert-MockCalled -CommandName New-ADOrganizationalUnit -ParameterFilter { $Name -eq $testPresentParams.Name } -Scope It
            }

            It 'Calls "New-ADOrganizationalUnit" with credentials when specified' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit
                Mock -CommandName New-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential }

                Set-TargetResource @testPresentParams -Credential $testCredential
                Assert-MockCalled -CommandName New-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Set-ADOrganizationalUnit" when "Ensure" = "Present" and OU does exist' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                Mock -CommandName Set-ADOrganizationalUnit

                Set-TargetResource @testPresentParams
                Assert-MockCalled -CommandName Set-ADOrganizationalUnit -Scope It
            }

            It 'Calls "Set-ADOrganizationalUnit" with credentials when specified' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                Mock -CommandName Set-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential }

                Set-TargetResource @testPresentParams -Credential $testCredential
                Assert-MockCalled -CommandName Set-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Remove-ADOrganizationalUnit" when "Ensure" = "Absent" and OU does exist but is unprotected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                    $unprotectedFakeAdOu = $protectedFakeAdOu.Clone()
                    $unprotectedFakeAdOu['ProtectedFromAccidentalDeletion'] = $false
                    return [PSCustomObject] $unprotectedFakeAdOu
                }
                Mock -CommandName Remove-ADOrganizationalUnit

                Set-TargetResource @testAbsentParams
                Assert-MockCalled -CommandName Remove-ADOrganizationalUnit -Scope It
            }

            It 'Calls "Remove-ADOrganizationalUnit" when "Ensure" = "Absent" and OU does exist and is protected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                Mock -CommandName Remove-ADOrganizationalUnit

                Set-TargetResource @testAbsentParams
                Assert-MockCalled -CommandName Remove-ADOrganizationalUnit -Scope It
            }

            It 'Calls "Remove-ADOrganizationalUnit" with credentials when specified' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                Mock -CommandName Remove-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential }

                Set-TargetResource @testAbsentParams -Credential $testCredential
                Assert-MockCalled -CommandName Remove-ADOrganizationalUnit -ParameterFilter { $Credential -eq $testCredential } -Scope It
            }

            It 'Calls "Set-ADOrganizationalUnit" when "Ensure" = "Absent", OU does exist but is protected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject] $protectedFakeAdOu }
                Mock -CommandName Remove-ADOrganizationalUnit
                Mock -CommandName Set-ADOrganizationalUnit

                Set-TargetResource @testAbsentParams
                Assert-MockCalled -CommandName Set-ADOrganizationalUnit -Scope It
            }

            It 'Does not call "Set-ADOrganizationalUnit" when "Ensure" = "Absent", OU does exist but is unprotected' {
                Mock -CommandName Assert-Module
                Mock -CommandName Get-ADOrganizationalUnit -MockWith {
                    $unprotectedFakeAdOu = $protectedFakeAdOu.Clone()
                    $unprotectedFakeAdOu['ProtectedFromAccidentalDeletion'] = $false
                    return [PSCustomObject] $unprotectedFakeAdOu
                }
                Mock -CommandName Remove-ADOrganizationalUnit
                Mock -CommandName Set-ADOrganizationalUnit

                Set-TargetResource @testAbsentParams
                Assert-MockCalled -CommandName Set-ADOrganizationalUnit -Scope It -Exactly 0
            }

            It "Calls Restore-AdCommonObject when RestoreFromRecycleBin is used" {
                $restoreParam = $testPresentParams.Clone()
                $restoreParam.RestoreFromRecycleBin = $true
                Mock -CommandName Get-TargetResource -MockWith { return @{Ensure = 'Absent'}}
                Mock -CommandName Restore-ADCommonObject -MockWith { return [PSCustomObject] $protectedFakeAdOu }

                Set-TargetResource @restoreParam

                Assert-MockCalled -CommandName Restore-AdCommonObject -Scope It
                Assert-MockCalled -CommandName New-ADOrganizationalUnit -Scope It -Exactly -Times 0
            }

            It "Calls New-ADOrganizationalUnit when RestoreFromRecycleBin is used and if no object was found in the recycle bin" {
                $restoreParam = $testPresentParams.Clone()
                $restoreParam.RestoreFromRecycleBin = $true
                Mock -CommandName Get-TargetResource -MockWith { return @{Ensure = 'Absent'}}
                Mock -CommandName New-ADOrganizationalUnit
                Mock -CommandName Restore-ADCommonObject

                Set-TargetResource @restoreParam

                Assert-MockCalled -CommandName Restore-AdCommonObject -Scope It
                Assert-MockCalled -CommandName New-ADOrganizationalUnit -Scope It
            }

            It "Throws if the object cannot be restored" {
                $restoreParam = $testPresentParams.Clone()
                $restoreParam.RestoreFromRecycleBin = $true
                Mock -CommandName Get-TargetResource -MockWith { return @{Ensure = 'Absent'}}
                Mock -CommandName New-ADOrganizationalUnit
                Mock -CommandName Restore-ADCommonObject -MockWith { throw (New-Object -TypeName System.InvalidOperationException)}

                {Set-TargetResource @restoreParam;} | Should -Throw

                Assert-MockCalled -CommandName Restore-AdCommonObject -Scope It
                Assert-MockCalled -CommandName New-ADOrganizationalUnit -Scope It -Exactly -Times 0
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
