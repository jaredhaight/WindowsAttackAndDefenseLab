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

Configuration myChocoConfig
{
   Import-DscResource -Module cChoco
   Node "localhost"
   {
      LocalConfigurationManager
      {
          DebugMode = 'ForceModuleImport'
      }
      cChocoInstaller installChoco
      {
        InstallDir = "c:\choco"
      }
      cChocoPackageInstaller installChrome
      {
        Name        = "googlechrome"
        DependsOn   = "[cChocoInstaller]installChoco"
        #This will automatically try to upgrade if available, only if a version is not explicitly specified.
        AutoUpgrade = $True
      }
      cChocoPackageInstaller installAtomSpecificVersion
      {
        Name = "atom"
        Version = "0.155.0"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller installGit
      {
         Ensure = 'Present'
         Name = "git"
         Params = "/Someparam "
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstaller noFlashAllowed
      {
         Ensure = 'Absent'
         Name = "flashplayerplugin"
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstallerSet installSomeStuff
      {
         Ensure = 'Present'
         Name = @(
			"git"
			"skype"
			"7zip"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
      cChocoPackageInstallerSet stuffToBeRemoved
      {
         Ensure = 'Absent'
         Name = @(
			"vlc"
			"ruby"
			"adobeair"
		)
         DependsOn = "[cChocoInstaller]installChoco"
      }
   }
}

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose -force
