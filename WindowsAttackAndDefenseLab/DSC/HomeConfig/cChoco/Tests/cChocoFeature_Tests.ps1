# Copyright (c) 2017 Chocolatey Software, Inc.
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


$ResourceName = ((Split-Path $MyInvocation.MyCommand.Path -Leaf) -split '_')[0]
$ResourceFile = (Get-DscResource -Name $ResourceName).Path

$TestsPath    = (split-path -path $MyInvocation.MyCommand.Path -Parent)
$ResourceFile = Get-ChildItem -Recurse $TestsPath\.. -File | Where-Object {$_.name -eq "$ResourceName.psm1"}

Import-Module -Name $ResourceFile.FullName


#---------------------------------#
# Pester tests for cChocoInstall  #
#---------------------------------#
Describe "Testing cChocoFeature" {

    Context "Test-TargetResource" {

        mock -ModuleName cChocoFeature -CommandName Get-ChocoFeature -MockWith {
            @([pscustomobject]@{
                Name = "allowGlobalConfirmation"
                State = "Enabled"
                Description = "blah"
            },
            [pscustomobject]@{
                Name = "powershellhost"
                State = "Disabled"
                Description = "blah"
            } )| Where-Object { $_.Name -eq $FeatureName }
        } -Verifiable


        it 'Test-TargetResource returns true when Present and Enabled.' {
            Test-TargetResource -FeatureName 'allowGlobalConfirmation' -Ensure 'Present' | should be $true
        }

        it 'Test-TargetResource returns false when Present and Disabled' {
            Test-TargetResource -FeatureName 'powershellhost' -Ensure 'Present' | should be $false
        }

        it 'Test-TargetResource returns false when Absent and Enabled' {
            Test-TargetResource -FeatureName 'allowGlobalConfirmation' -Ensure 'Absent' | Should be $false
        }

        it 'Test-TargetResource returns true when Absent and Disabled' {
            Test-TargetResource -FeatureName 'powershellhost' -Ensure 'Absent' | should be $true
        }

    }

    Context "Set-TargetResource" {

        InModuleScope -ModuleName cChocoFeature -ScriptBlock {
            function choco {}
            mock choco {} 
        }

        Set-TargetResource -FeatureName "TestFeature" -Ensure "Present"

        it "Present - Should have called choco, with enable" { 
            Assert-MockCalled -CommandName choco -ModuleName cChocoFeature -ParameterFilter {
                $args -contains "enable"
            }
        }

        Set-TargetResource -FeatureName "TestFeature" -Ensure "Absent"

        it "Absent - Should have called choco, with disable" {
            Assert-MockCalled -CommandName choco -ModuleName cChocoFeature -ParameterFilter {
                $args -contains "disable"
            }
        }
    }
}