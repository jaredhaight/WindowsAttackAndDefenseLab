$TestTimeZone = [PSObject]@{
    TimeZone         = 'Pacific Standard Time'
    IsSingleInstance = 'Yes'
}

configuration xTimezone_Config {
    Import-DscResource -ModuleName xTimeZone
    node localhost {
        xTimeZone Integration_Test {
            TimeZone         = $TestTimeZone.TimeZone
            IsSingleInstance = $TestTimeZone.IsSingleInstance
        }
    }
}
