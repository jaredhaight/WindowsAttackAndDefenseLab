$script:DSCModuleName      = 'xSystemSecurity' 
$script:DSCResourceName    = 'MSFT_xFileSystemAccessRule' 

[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration 

try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    New-Item -Path "$env:SystemDrive\SampleFolder" -ItemType Directory

    Describe "$($script:DSCResourceName)_Integration" {

        It 'New rule - Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_NewRule -OutputPath `$TestDrive"
            } | Should not throw
        }

        It "New rule - Should apply without throwing" {
            {
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'New rule - Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'New rule - Should have set the resource and all the parameters should match' {
            Test-DscConfiguration -Path $TestDrive | Should Be $true
        }


        It 'Update rule - Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_UpdateRule -OutputPath `$TestDrive"
            } | Should not throw
        }

        It "Update rule - Should apply without throwing" {
            {
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }


        It 'Update rule - Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Remove rule - Should have set the resource and all the parameters should match' {
            Test-DscConfiguration -Path $TestDrive | Should Be $true
        }

        It 'Remove rule - Should compile without throwing' {
            {
                Invoke-Expression -Command "$($script:DSCResourceName)_RemoveRule -OutputPath `$TestDrive"
            } | Should not throw
        }

        It "Remove rule - Should apply without throwing" {
            {
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Remove rule - Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'New rule - Should have set the resource and all the parameters should match' {
            Test-DscConfiguration -Path $TestDrive | Should Be $true
        }


        Remove-Item -Path "$env:SystemDrive\SampleFolder" -Recurse -Force -Confirm:$false
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
