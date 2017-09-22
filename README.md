# Modern Windows Attacks and Defense Lab

This is the lab configuration for the Modern Windows Attacks and Defense class that Sean Metcalf (@pyrotek3) and I teach. It leverages [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates) and [Desired State Config](https://docs.microsoft.com/en-us/powershell/dsc/overview) to spin up the lab.

# Lab Environment
The lab consists of the following servers:

#### DC01
* Windows 2012 R2
* Active Directory
* DNS
* File Sharing

#### TerminalServer
* Windows 2012 R2
* Remote Desktop Services

#### AdminDesktop
* Windows 2012 R2

#### UserDesktop
* Windows 2012 R2

#### Home
* Windows 2016
* RSAT

#### Pwnbox
* Ubuntu 16.04
* Metasploit