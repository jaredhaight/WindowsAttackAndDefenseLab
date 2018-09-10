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

Configuration cChocoPackageInstallerSet
{
<#
.SYNOPSIS
Composite DSC Resource allowing you to specify multiple choco packages in a single resource block.
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure='Present',
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source
    )

    foreach ($pName in $Name) {
        cChocoPackageInstaller "cChocoPackageInstaller_$($Ensure)_$($pName)" {
            Ensure = $Ensure
            Name = $pName
            Source = $Source
        }
    }
}
