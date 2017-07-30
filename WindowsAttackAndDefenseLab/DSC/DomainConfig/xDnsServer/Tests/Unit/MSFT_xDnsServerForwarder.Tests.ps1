$Global:DSCModuleName      = 'xDnsServer'
$Global:DSCResourceName    = 'MSFT_xDnsServerForwarder'

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
        #region Pester Test Initialization
        $forwarders = '192.168.0.1','192.168.0.2'
        $testParams = @{
            IsSingleInstance = 'Yes'
            IPAddresses = $forwarders
        }
        $fakeCimInstance = @{
            Forwarders = $forwarders
        }
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock -CommandName Get-CimInstance -MockWith {return $fakeCimInstance}
                $targetResource = Get-TargetResource @testParams
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
            }

            It "Returns IPAddresses = $($testParams.IPAddresses) when forwarders exist" {
                Mock -CommandName Get-CimInstance -MockWith {return $fakeCimInstance}
                $targetResource = Get-TargetResource @testParams
                $targetResource.IPAddresses | Should Be $testParams.IPAddresses
            }

            It "Returns an empty IPAddresses when forwarders don't exist" {
                Mock -CommandName Get-CimInstance -MockWith {}
                $targetResource = Get-TargetResource @testParams
                $targetResource.IPAddresses | Should Be $null
            }
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            It 'Returns a "System.Boolean" object type' {
                Mock -CommandName Get-CimInstance -MockWith {return $fakeCimInstance}
                $targetResource =  Test-TargetResource @testParams
                $targetResource -is [System.Boolean] | Should Be $true
            }

            It 'Passes when forwarders match' {
                Mock -CommandName Get-CimInstance -MockWith {return $fakeCimInstance}
                Test-TargetResource @testParams | Should Be $true
            }

            It "Fails when forwarders don't match" {
                Mock -CommandName Get-CimInstance -MockWith {}
                Test-TargetResource @testParams | Should Be $false
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            It "Calls Set-CimInstance once" {
                Mock -CommandName Set-CimInstance -MockWith {}
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Set-CimInstance -Times 1 -Exactly -Scope It
            }
        }
    } #end InModuleScope
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
