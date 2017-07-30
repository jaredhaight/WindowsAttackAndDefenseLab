configuration MSFT_xFileSystemAccessRule_NewRule {
    Import-DscResource -ModuleName 'xSystemSecurity'
    node localhost {
        xFileSystemAccessRule Integration_Test {
            Path = "$($env:SystemDrive)\SampleFolder"
            Identity = "NT AUTHORITY\NETWORK SERVICE"
            Rights = @("Read","Synchronize")
        }
    }
}

configuration MSFT_xFileSystemAccessRule_UpdateRule {
    Import-DscResource -ModuleName 'xSystemSecurity'
    node localhost {
        xFileSystemAccessRule Integration_Test {
            Path = "$($env:SystemDrive)\SampleFolder"
            Identity = "NT AUTHORITY\NETWORK SERVICE"
            Rights = @("FullControl")
        }
    }
}

configuration MSFT_xFileSystemAccessRule_RemoveRule {
    Import-DscResource -ModuleName 'xSystemSecurity'
    node localhost {
        xFileSystemAccessRule Integration_Test {
            Path = "$($env:SystemDrive)\SampleFolder"
            Identity = "NT AUTHORITY\NETWORK SERVICE"
            Ensure = "Absent"
        }
    }
}

