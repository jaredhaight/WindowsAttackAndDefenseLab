$Global:DSCModuleName      = 'xDnsServer' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xDnsRecord' # Example MSFT_xFirewall

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
        $testPresentParams = @{
            Name = "test"
            Zone = "contoso.com"
            Target = "192.168.0.1"
            Type = "ARecord"
            Ensure = "Present"
        }
        $testAbsentParams = @{
            Name = $testPresentParams.Name
            Zone = $testPresentParams.Zone
            Target = $testPresentParams.Target
            Type = $testPresentParams.Type
            Ensure = "Absent"
        }
        $fakeDnsServerResourceRecord = @{
            HostName = $testPresentParams.Name;
            RecordType = 'A'
            TimeToLive = '01:00:00'
            RecordData = @{
                IPv4Address = @{
                    IPAddressToString = $testPresentParams.Target
                }
            }
        }
        #endregion

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            
            It "Returns Ensure is Present when DNS record exists" {
                Mock Get-DnsServerResourceRecord { return $fakeDnsServerResourceRecord }
                (Get-TargetResource @testPresentParams).Ensure | Should Be 'Present'
            }

            It "Returns Ensure is Absent when DNS record does not exist" {
                Mock Get-DnsServerResourceRecord { return $null }
                (Get-TargetResource @testPresentParams).Ensure | Should Be 'Absent'
            } 
        
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            
            It "Fails when no DNS record exists and Ensure is Present" {
                Mock Get-TargetResource { return $testAbsentParams }
                Test-TargetResource @testPresentParams | Should Be $false
            }
            
            It "Fails when a record exists, target does not match and Ensure is Present" {
                Mock Get-TargetResource { 
                    return @{
                        Name = $testPresentParams.Name
                        Zone = $testPresentParams.Zone
                        Target = "192.168.0.10"
                        Ensure = $testPresentParams.Ensure
                    }
                }
                Test-TargetResource @testPresentParams | Should Be $false
            }
            
            It "Fails when round-robin record exists, target does not match and Ensure is Present (Issue #23)" {
                Mock Get-TargetResource { 
                    return @{
                        Name = $testPresentParams.Name
                        Zone = $testPresentParams.Zone
                        Target = @("192.168.0.10","192.168.0.11")
                        Ensure = $testPresentParams.Ensure
                    }
                }
                Test-TargetResource @testPresentParams | Should Be $false
            }
            
            It "Fails when a record exists and Ensure is Absent" {
                Mock Get-TargetResource { return $testPresentParams }
                Test-TargetResource @testAbsentParams | Should Be $false
            }
            
            It "Fails when round-robin record exists, and Ensure is Absent (Issue #23)" {
                Mock Get-TargetResource { 
                    return @{
                        Name = $testPresentParams.Name
                        Zone = $testPresentParams.Zone
                        Target = @("192.168.0.1","192.168.0.2")
                        Ensure = $testPresentParams.Ensure
                    }
                }
                Test-TargetResource @testAbsentParams | Should Be $false
            }

            It "Passes when record exists, target matches and Ensure is Present" {
                Mock Get-TargetResource {  return $testPresentParams } 
                Test-TargetResource @testPresentParams | Should Be $true
            }

            It "Passes when round-robin record exists, target matches and Ensure is Present (Issue #23)" {
                Mock Get-TargetResource { 
                    return @{
                        Name = $testPresentParams.Name
                        Zone = $testPresentParams.Zone
                        Target = @("192.168.0.1","192.168.0.2")
                        Ensure = $testPresentParams.Ensure
                    }
                }
                Test-TargetResource @testPresentParams | Should Be $true
            }

            It "Passes when record does not exist and Ensure is Absent" {
                Mock Get-TargetResource { return $testAbsentParams } 
                Test-TargetResource @testAbsentParams | Should Be $true
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            It "Calls Add-DnsServerResourceRecord in the set method when Ensure is Present" {
                Mock Add-DnsServerResourceRecord { return $null }
                Set-TargetResource @testPresentParams 
                Assert-MockCalled Add-DnsServerResourceRecord -Scope It
            }
            
            It "Calls Remove-DnsServerResourceRecord in the set method when Ensure is Absent" {
                Mock Remove-DnsServerResourceRecord { return $null }
                Set-TargetResource @testAbsentParams 
                Assert-MockCalled Remove-DnsServerResourceRecord -Scope It
            }
        }
        #endregion

    } #end InModuleScope
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
