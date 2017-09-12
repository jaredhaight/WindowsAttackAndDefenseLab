[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if (Get-Module -Name TimezoneHelper -ErrorAction SilentlyContinue)
{
    Remove-Module -Name TimezoneHelper
}
Import-Module -Name (Join-Path -Path $moduleRoot -ChildPath 'DSCResources\TimezoneHelper.psm1') -Force

#region Pester Tests
InModuleScope TimezoneHelper {
    Describe 'Get-TimezoneId' {
        Context "'Get-Timezone' not available and Current Timezone is set to 'Pacific Standard Time'" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' }
            Mock -CommandName Get-CimInstance -MockWith {
                @{ StandardName = 'Pacific Standard Time' }
            }
            It "Returns 'Pacific Standard Time'." {
                Get-TimezoneId | should be 'Pacific Standard Time'
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
            }
        }
        Context "'Get-Timezone' not available and Current Timezone is set to 'Russia TZ 11 Standard Time'" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' }
            Mock -CommandName Get-CimInstance -MockWith {
                @{ StandardName = 'Russia TZ 11 Standard Time' }
            }
            It "Returns 'Russia Time Zone 11'." {
                Get-TimezoneId | should be 'Russia Time Zone 11'
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
            }
        }
        Context "'Get-Timezone' available and Current Timezone is set to 'Pacific Standard Time'" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' } -MockWith { 'Get-Timezone' }
            function Get-Timezone { param () }
            Mock -CommandName Get-Timezone -MockWith {
                @{ StandardName = 'Pacific Standard Time' }
            }
            It "Returns 'Pacific Standard Time'." {
                Get-TimezoneId | should be 'Pacific Standard Time'
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Get-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName Get-Timezone -Exactly 1
            }
        }
    }

    Describe 'Test-TimezoneId' {
        Mock Get-TimeZoneId -MockWith { 'Russia Time Zone 11' }
        Context "Current timezone matches desired timezone" {
            It "Should return True" {
                Test-TimezoneId -TimeZoneId 'Russia Time Zone 11' | Should Be $True
            }
        }
        Context "Current timezone does not match desired timezone" {
            It "Should return False" {
                Test-TimezoneId -TimeZoneId 'GMT Standard Time' | Should Be $False
            }
        }
    }

    Describe 'Set-TimezoneId' {
        Context "'Set-Timezone' and 'Add-Type' is not available, Tzutil Returns 0" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' }
            Mock -CommandName 'TzUtil.exe' -MockWith { $Global:LASTEXITCODE = 0; return "OK" }
            Mock -CommandName Add-Type
            It "Should not throw exception" {
                { Set-TimezoneId -TimezoneId 'Eastern Standard Time' }  | Should Not Throw
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' } -Exactly 1
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName TzUtil.exe -Exactly 1
                Assert-MockCalled -CommandName Add-Type -Exactly 0
            }
        }
        Context "'Set-Timezone' is not available but 'Add-Type' is available" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' } -MockWith { 'Add-Type' }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' }
            Mock -CommandName 'TzUtil.exe' -MockWith { $Global:LASTEXITCODE = 0; return "OK" }
            Mock -CommandName Add-Type
            Mock -CommandName Set-TimeZoneUsingNET
            It "Should throw exception" {
                { Set-TimezoneId -TimezoneId 'Eastern Standard Time' }  | Should Not Throw
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' } -Exactly 1
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName TzUtil.exe -Exactly 0
                Assert-MockCalled -CommandName Add-Type -Exactly 0
                Assert-MockCalled -CommandName Set-TimeZoneUsingNET -Exactly 1
            }
        }
        Context "'Set-Timezone' is available" {
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' }
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' } -MockWith { 'Set-Timezone' }
            function Set-Timezone { param ( $id ) }
            Mock -CommandName Set-Timezone
            It "Should not throw exception" {
                { Set-TimezoneId -TimezoneId 'Eastern Standard Time' }  | Should Not Throw
            }
            It "Should call expected mocks" {
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Add-Type' } -Exactly 0
                Assert-MockCalled -CommandName Get-Command -ParameterFilter { $Name -eq 'Set-Timezone' } -Exactly 1
                Assert-MockCalled -CommandName Set-Timezone -Exactly 1
            }
        }
    }

    Describe 'Test-Command' {
        Context "Command 'Get-Timezone' exists" {
            Mock -CommandName Get-Command `
                -ParameterFilter {
                    $Name -eq 'Get-Timezone' -and `
                    $Module -eq 'Microsoft.PowerShell.Management'
                } `
                -MockWith { @{ Name = 'Get-Timezone' } }
            It "Should not throw exception" {
                Test-Command `
                    -Name 'Get-Timezone' `
                    -Module 'Microsoft.PowerShell.Management' | Should Be $True
            }
            It "Should call expected mocks" {
                Assert-MockCalled `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Get-Timezone' -and `
                        $Module -eq 'Microsoft.PowerShell.Management'
                    } `
                    -Exactly 1
            }
        }

        Context "Command 'Get-Timezone' does not exist" {
            Mock -CommandName Get-Command `
                -ParameterFilter {
                    $Name -eq 'Get-Timezone' -and `
                    $Module -eq 'Microsoft.PowerShell.Management'
                } `
                -MockWith { }
            It "Should not throw exception" {
                Test-Command `
                    -Name 'Get-Timezone' `
                    -Module 'Microsoft.PowerShell.Management' | Should Be $False
            }
            It "Should call expected mocks" {
                Assert-MockCalled `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Get-Timezone' -and `
                        $Module -eq 'Microsoft.PowerShell.Management'
                    } `
                    -Exactly 1
            }
        }
    }
}
