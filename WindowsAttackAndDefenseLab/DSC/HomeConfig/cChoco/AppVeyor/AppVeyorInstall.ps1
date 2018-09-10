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
# Header                          #
#---------------------------------#
Write-Host 'Running AppVeyor install script' -ForegroundColor Yellow

#---------------------------------#
# Install NuGet                   #
#---------------------------------#
Write-Host 'Installing NuGet PackageProvide'
$pkg = Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-Host "Installed NuGet version '$($pkg.version)'"

#---------------------------------#
# Install Modules                 #
#---------------------------------#
[version]$ScriptAnalyzerVersion = '1.8.1'
Install-Module -Name 'PSScriptAnalyzer' -Repository PSGallery -Force -ErrorAction Stop -MaximumVersion $ScriptAnalyzerVersion
Install-Module -Name 'Pester','xDSCResourceDesigner' -Repository PSGallery -Force -ErrorAction Stop

#---------------------------------#
# Update PSModulePath             #
#---------------------------------#
Write-Host 'Updating PSModulePath for DSC resource testing'
$env:PSModulePath = $env:PSModulePath + ";" + "C:\projects"

#---------------------------------#
# Validate                        #
#---------------------------------#
$RequiredModules  = 'PSScriptAnalyzer','Pester','xDSCResourceDesigner'
$InstalledModules = Get-Module -Name $RequiredModules -ListAvailable
if ( ($InstalledModules.count -lt $RequiredModules.Count) -or ($Null -eq $InstalledModules)) {
  throw "Required modules are missing."
} else {
  Write-Host 'All modules required found' -ForegroundColor Green
}
