# Copyright (c) 2017 Chocolatey Software, Inc.
# Copyright (c) 2013 - 2017 Lawrence Gripper & original authors/contributors from https://github.com/chocolatey/cChoco
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#----------------------------------------#
# Pester tests for cChocoPackageInstall  #
#----------------------------------------#
$ResourceName = ((Split-Path -Path $MyInvocation.MyCommand.Path -Leaf) -split '_')[0]
$ResourceFile = (Get-DscResource -Name $ResourceName).Path

$TestsPath    = (split-path -path $MyInvocation.MyCommand.Path -Parent)
$ResourceFile = Get-ChildItem -Recurse $TestsPath\.. -File | Where-Object {$_.name -eq "$ResourceName.psm1"}

Import-Module -Name $ResourceFile.FullName

Describe -Name "Testing $ResourceName loaded from $ResourceFile" -Fixture {
    Context -Name "Package is not installed" -Fixture {
        Mock -CommandName 'Get-ChocoInstalledPackage' -ModuleName 'cChocoPackageInstall' -MockWith {
            return [pscustomobject]@{
                'Name'    = 'NotGoogleChrome'
                'Version' = '1.0.0'
            }
        }

        $Scenario1 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Present'
        }
        It -name "Test-TargetResource -ensure 'Present' should return False" -test {
            Test-TargetResource @Scenario1 | Should Be $False
        }

        $Scenario2 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return True" -test {
            Test-TargetResource @Scenario2 | Should Be $True
        }

        $Scenario3 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Absent'
            Version = '1.0.0'
        }
        It -name "Test-TargetResource -ensure 'Absent' -version '1.0.0' should return True" -test {
            Test-TargetResource @Scenario3 | Should Be $True
        }

        $Scenario4 = @{
            Name        = 'GoogleChrome'
            Ensure      = 'Absent'
            AutoUpgrade = $True
        }
        It -name "Test-TargetResource -ensure 'Absent' -AutoUpgrade should return True" -test {
            Test-TargetResource @Scenario4 | Should Be $True
        }

        $Scenario5 = @{
            Name        = 'GoogleChrome'
            Ensure      = 'Absent'
            Version     = '1.0'
            AutoUpgrade = $True
        }
        It -name "Test-TargetResource -ensure 'Absent' -version '1.0.0' -AutoUpgrade should return True" -test {
            Test-TargetResource @Scenario5 | Should Be $True
        }
    }

    Context -Name "Package is installed with version 1.0.0" -Fixture {
        Mock -CommandName 'Get-ChocoInstalledPackage' -ModuleName 'cChocoPackageInstall' -MockWith {
            return [pscustomobject]@{
                'Name'    = 'GoogleChrome'
                'Version' = '1.0.0'
            }
        }

        $Scenario1 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Present'
        }
        It -name "Test-TargetResource -ensure 'Present' should return True" -test {
            Test-TargetResource @Scenario1 | Should Be $True
        }

        $Scenario2 = @{
            Name   = 'GoogleChrome'
            Ensure = 'Absent'
        }
        It -name "Test-TargetResource -ensure 'Absent' should return False" -test {
            Test-TargetResource @Scenario2 | Should Be $False
        }

        $Scenario3 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Present'
            Version = '1.0.0'
        }

        It -name "Test-TargetResource -ensure 'Present' -version '1.0.0' should return True" -test {
            Test-TargetResource @Scenario3 | Should Be $True
        }

        $Scenario4 = @{
            Name    = 'GoogleChrome'
            Ensure  = 'Present'
            Version = '1.0.1'
        }

        It -name "Test-TargetResource -ensure 'Present' -version '1.0.1' should return False" -test {
            Test-TargetResource @Scenario4 | Should Be $False
        }
    }
}

#Clean-up
Remove-Module cChocoPackageInstall
