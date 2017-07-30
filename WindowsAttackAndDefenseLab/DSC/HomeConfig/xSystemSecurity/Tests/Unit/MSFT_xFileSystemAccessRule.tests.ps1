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
    -TestType Unit 

Import-Module (Join-Path $script:moduleRoot "\DSCResources\$script:DSCResourceName\$script:DSCResourceName.psm1") -Force


try
{
    Describe "xFileSystemAccessRule" {
        InModuleScope -ModuleName $script:DSCResourceName {

            Mock Set-Acl {}
            Mock Test-Path { return $true }

            Context "No permissions exist for a user, but should" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Rights = @("Read","Synchronize")
                }
                Mock Get-Acl { 
                    return @{
                        Access = @()
                    } | Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {} -PassThru `
                      | Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {} -PassThru
                }

                It "should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "should add the permission in the set method" {
                    Set-TargetResource @testParams 
                    Assert-MockCalled -CommandName Set-Acl
                }
            }

            Context "A permission exists and should, but the rights are incorrect" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Rights = @("Read","Synchronize")
                }
                Mock Get-Acl { 
                    return @{
                        Access = @(
                            @{
                                IdentityReference = $testParams.Identity
                                FileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl
                            }
                        )
                    } | Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {} -PassThru `
                      | Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {} -PassThru
                }

                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "should add the permission in the set method" {
                    Set-TargetResource @testParams 
                    Assert-MockCalled -CommandName Set-Acl
                }
            } 

            Context "A permission exists and should, including correct rights" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Rights = @("Read","Synchronize")
                }
                Mock Get-Acl { 
                    return @{
                        Access = @(
                            @{
                                IdentityReference = $testParams.Identity
                                FileSystemRights = [System.Security.AccessControl.FileSystemRights]$testParams.Rights
                            }
                        )
                    } | Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {} -PassThru `
                      | Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {} -PassThru
                }

                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "A permission exists that shouldn't" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Ensure = "Absent"
                }
                Mock Get-Acl { 
                    return @{
                        Access = @(
                            @{
                                IdentityReference = $testParams.Identity
                                FileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl
                            }
                        )
                    } | Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {} -PassThru `
                      | Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {} -PassThru
                }

                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "should add the permission in the set method" {
                    Set-TargetResource @testParams 
                    Assert-MockCalled -CommandName Set-Acl
                }
            }

            Context "A permission doesn't exist and shouldn't" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Ensure = "Absent"
                }
                Mock Get-Acl { 
                    return @{
                        Access = @()
                    } | Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {} -PassThru `
                      | Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {} -PassThru
                }

                It "should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Mock Test-Path { return $false }

            Context "A path doesn't exist" {
                $testParams = @{
                    Path = "$($env:SystemDrive)\TestFolder"
                    Identity = "NT AUTHORITY\NETWORK SERVICE"
                    Rights = @("Read","Synchronize")
                }

                It "should throw from the get method" {
                    { Get-TargetResource @testParams } | Should Throw
                }

                It "should throw from the test method" {
                    { Test-TargetResource @testParams } | Should Throw
                }

                It "should throw from the set method" {
                    { Set-TargetResource @testParams } | Should Throw
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
