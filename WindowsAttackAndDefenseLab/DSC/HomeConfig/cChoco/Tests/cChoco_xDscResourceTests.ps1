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

#---------------------------------#
# xDscResourceTests Pester        #
#---------------------------------#
$DSC = Get-DscResource | Where-Object {$_.Module.Name -eq 'cChoco'}

Describe 'Testing all DSC resources using xDscResource designer.' {
  foreach ($Resource in $DSC)
  {
    if (-not ($Resource.ImplementedAs -eq 'Composite') ) {
      $ResourceName = $Resource.ResourceType
      $Mof          = Get-ChildItem “$PSScriptRoot\..\” -Filter "$resourcename.schema.mof" -Recurse

      Context “Testing DscResource '$ResourceName' using Test-xDscResource” {
        It 'Test-xDscResource should return $true' {
          Test-xDscResource -Name $ResourceName | Should Be $true
        }
      }

      Context “Testing DscSchema '$ResourceName' using Test-xDscSchema” {
        It 'Test-xDscSchema should return true' {
          Test-xDscSchema -Path $Mof.FullName | Should Be $true
        }
      }
    }
  }
}
