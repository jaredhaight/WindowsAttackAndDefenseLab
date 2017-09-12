$Global:DSCModuleName      = 'xTimeZone'
$Global:DSCResourceName    = 'xTimeZone'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit
#endregion

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $Global:DSCResourceName {
        Describe 'Schema' {
            it 'IsSingleInstance should be mandatory with one value.' {
                $timeZoneResource = Get-DscResource -Name xTimeZone
                $timeZoneResource.Properties.Where{$_.Name -eq 'IsSingleInstance'}.IsMandatory | should be $true
                $timeZoneResource.Properties.Where{$_.Name -eq 'IsSingleInstance'}.Values | should be 'Yes'
            }
        }

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Mock `
                -ModuleName xTimezone `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            $TimeZone = Get-TargetResource `
                -TimeZone 'Pacific Standard Time' `
                -IsSingleInstance 'Yes'

            It 'Should return hashtable with Key TimeZone'{
                $TimeZone.ContainsKey('TimeZone') | Should Be $true
            }

            It 'Should return hashtable with Value that matches "Pacific Standard Time"'{
                $TimeZone.TimeZone = 'Pacific Standard Time'
            }
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            Mock `
                -ModuleName xTimezone `
                -CommandName Set-TimeZoneId
            Mock `
                -ModuleName xTimezone `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Eastern Standard Time' }

            It 'Call Set-TimeZoneId' {
                Set-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes'
                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -ModuleName xTimezone `
                    -Exactly 1
            }

            It 'Should not call Set-TimeZoneId when Current TimeZone already set to desired State'{
                $SystemTimeZone = Get-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes'
                Set-TargetResource `
                    -TimeZone $SystemTimeZone.TimeZone `
                    -IsSingleInstance 'Yes'
                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -ModuleName xTimezone `
                    -Scope It `
                    -Exactly 0
            }
        }

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Mock `
                -ModuleName TimezoneHelper `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            It 'Should return true when Test is passed Time Zone thats already set'{
                Test-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' | Should Be $true
            }

            It 'Should return false when Test is passed Time Zone that is not set'{
                Test-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' | Should Be $false
            }

        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
