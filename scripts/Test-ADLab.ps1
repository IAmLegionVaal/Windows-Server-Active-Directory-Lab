#requires -Version 5.1

<#
.SYNOPSIS
    Performs read-only validation checks on a Windows Active Directory lab device.

.DESCRIPTION
    This helper was added to the repository after the lab was completed to make
    client-side validation repeatable. It does not join or remove a computer
    from a domain and does not repair or modify the secure channel.

.PARAMETER DomainName
    Optional DNS name of the Active Directory domain. When omitted, the script
    uses the domain reported by Win32_ComputerSystem.

.PARAMETER DomainController
    Optional hostname or FQDN of the domain controller. When omitted, the script
    attempts to discover a domain controller with nltest.

.EXAMPLE
    .\Test-ADLab.ps1

.EXAMPLE
    .\Test-ADLab.ps1 -DomainName "lab.example" -DomainController "dc01.lab.example"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DomainController
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$results = New-Object 'System.Collections.Generic.List[object]'

function Add-CheckResult {
    param(
        [Parameter(Mandatory)]
        [string]$Check,

        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Fail', 'Warning', 'Info', 'Skipped')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Details
    )

    $results.Add([pscustomobject]@{
        Check   = $Check
        Status  = $Status
        Details = $Details
    })
}

function Invoke-SafeCheck {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    }
    catch {
        Add-CheckResult -Check $Name -Status 'Fail' -Details $_.Exception.Message
    }
}

Write-Host ''
Write-Host 'Active Directory Lab Validation' -ForegroundColor Cyan
Write-Host ('=' * 32)
Write-Host ('Computer: {0}' -f $env:COMPUTERNAME)
Write-Host ('Started : {0}' -f (Get-Date))
Write-Host ''

$computerSystem = $null

Invoke-SafeCheck -Name 'Computer information' -ScriptBlock {
    $script:computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

    if ($computerSystem.PartOfDomain) {
        $membershipText = "Domain joined to $($computerSystem.Domain)"
        $membershipStatus = 'Pass'
    }
    else {
        $membershipText = "Not domain joined; current workgroup/domain value: $($computerSystem.Domain)"
        $membershipStatus = 'Fail'
    }

    Add-CheckResult -Check 'Domain membership' -Status $membershipStatus -Details $membershipText

    $roleText = 'Win32 domain role value: {0}' -f $computerSystem.DomainRole
    Add-CheckResult -Check 'Computer role' -Status 'Info' -Details $roleText
}

if (-not $DomainName -and $computerSystem -and $computerSystem.PartOfDomain) {
    $DomainName = $computerSystem.Domain
}

Invoke-SafeCheck -Name 'Current identity' -ScriptBlock {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    if ($identity -match '\\') {
        $identityStatus = 'Info'
    }
    else {
        $identityStatus = 'Warning'
    }

    Add-CheckResult -Check 'Current sign-in identity' -Status $identityStatus -Details $identity
}

Invoke-SafeCheck -Name 'DNS client configuration' -ScriptBlock {
    $dnsAddresses = Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object { $_.ServerAddresses -and $_.ServerAddresses.Count -gt 0 } |
        ForEach-Object { $_.ServerAddresses } |
        Sort-Object -Unique

    if ($dnsAddresses) {
        Add-CheckResult -Check 'Configured IPv4 DNS servers' -Status 'Info' -Details ($dnsAddresses -join ', ')
    }
    else {
        Add-CheckResult -Check 'Configured IPv4 DNS servers' -Status 'Warning' -Details 'No IPv4 DNS server addresses were returned.'
    }
}

if ($DomainName) {
    Invoke-SafeCheck -Name 'Domain DNS resolution' -ScriptBlock {
        $records = Resolve-DnsName -Name $DomainName -ErrorAction Stop
        $recordSummary = $records |
            Where-Object { $_.IPAddress -or $_.NameHost } |
            Select-Object -First 4 |
            ForEach-Object {
                if ($_.IPAddress) {
                    $_.IPAddress
                }
                else {
                    $_.NameHost
                }
            }

        if ($recordSummary) {
            $domainDnsDetails = $recordSummary -join ', '
        }
        else {
            $domainDnsDetails = 'DNS query completed.'
        }

        Add-CheckResult -Check 'Resolve domain name' -Status 'Pass' -Details $domainDnsDetails
    }

    Invoke-SafeCheck -Name 'Domain controller discovery' -ScriptBlock {
        $nltestOutput = & nltest.exe "/dsgetdc:$DomainName" 2>&1
        $nltestExitCode = $LASTEXITCODE

        if ($nltestExitCode -eq 0) {
            $firstNltestLine = ($nltestOutput | Select-Object -First 1) -join ' '
            Add-CheckResult -Check 'Discover domain controller' -Status 'Pass' -Details $firstNltestLine

            if (-not $DomainController) {
                $dcMatch = $nltestOutput |
                    Select-String -Pattern 'DC:\s+\\\\([^\s]+)' |
                    Select-Object -First 1

                if ($dcMatch -and $dcMatch.Matches.Count -gt 0) {
                    $script:DomainController = $dcMatch.Matches[0].Groups[1].Value
                }
            }
        }
        else {
            $nltestError = ($nltestOutput -join ' ').Trim()
            Add-CheckResult -Check 'Discover domain controller' -Status 'Fail' -Details $nltestError
        }
    }

    Invoke-SafeCheck -Name 'LDAP service record' -ScriptBlock {
        $srvName = "_ldap._tcp.dc._msdcs.$DomainName"
        $srvRecords = Resolve-DnsName -Name $srvName -Type SRV -ErrorAction Stop
        $targets = $srvRecords |
            Where-Object { $_.NameTarget } |
            Select-Object -ExpandProperty NameTarget -Unique

        if ($targets) {
            $srvDetails = $targets -join ', '
        }
        else {
            $srvDetails = 'SRV query completed.'
        }

        Add-CheckResult -Check 'Resolve AD LDAP SRV record' -Status 'Pass' -Details $srvDetails
    }
}
else {
    Add-CheckResult -Check 'Domain-dependent checks' -Status 'Skipped' -Details 'No domain name was supplied or detected.'
}

$isDomainController = $false
if ($computerSystem) {
    $isDomainController = $computerSystem.DomainRole -ge 4
}

if ($computerSystem -and $computerSystem.PartOfDomain -and -not $isDomainController) {
    Invoke-SafeCheck -Name 'Secure channel' -ScriptBlock {
        $secureChannel = Test-ComputerSecureChannel -ErrorAction Stop

        if ($secureChannel) {
            $secureChannelStatus = 'Pass'
        }
        else {
            $secureChannelStatus = 'Fail'
        }

        $secureChannelDetails = 'Test-ComputerSecureChannel returned {0}.' -f $secureChannel
        Add-CheckResult -Check 'Domain secure channel' -Status $secureChannelStatus -Details $secureChannelDetails
    }
}
elseif ($isDomainController) {
    Add-CheckResult -Check 'Domain secure channel' -Status 'Skipped' -Details 'This computer is a domain controller; the client secure-channel test was skipped.'
}
else {
    Add-CheckResult -Check 'Domain secure channel' -Status 'Skipped' -Details 'The computer is not joined to a domain.'
}

if ($DomainController) {
    Invoke-SafeCheck -Name 'Domain controller DNS resolution' -ScriptBlock {
        $dcRecords = Resolve-DnsName -Name $DomainController -ErrorAction Stop
        $dcAddresses = $dcRecords |
            Where-Object { $_.IPAddress } |
            Select-Object -ExpandProperty IPAddress -Unique

        if ($dcAddresses) {
            $dcDnsDetails = $dcAddresses -join ', '
        }
        else {
            $dcDnsDetails = 'DNS query completed.'
        }

        Add-CheckResult -Check 'Resolve domain controller' -Status 'Pass' -Details $dcDnsDetails
    }

    $ports = @(
        @{ Port = 53;  Service = 'DNS' },
        @{ Port = 88;  Service = 'Kerberos' },
        @{ Port = 389; Service = 'LDAP' },
        @{ Port = 445; Service = 'SMB' }
    )

    foreach ($portTest in $ports) {
        $currentPort = $portTest.Port
        $currentService = $portTest.Service

        Invoke-SafeCheck -Name "$currentService port $currentPort" -ScriptBlock {
            $test = Test-NetConnection -ComputerName $DomainController -Port $currentPort -WarningAction SilentlyContinue

            if ($test.TcpTestSucceeded) {
                $portStatus = 'Pass'
            }
            else {
                $portStatus = 'Fail'
            }

            $portDetails = 'Target: {0}; Connected: {1}' -f $DomainController, $test.TcpTestSucceeded
            Add-CheckResult -Check "$currentService TCP/$currentPort" -Status $portStatus -Details $portDetails
        }
    }
}
else {
    Add-CheckResult -Check 'Domain controller connectivity' -Status 'Skipped' -Details 'No domain controller hostname was supplied or discovered.'
}

Invoke-SafeCheck -Name 'Netlogon service' -ScriptBlock {
    $netlogon = Get-Service -Name Netlogon

    if ($netlogon.Status -eq 'Running') {
        $netlogonStatus = 'Pass'
    }
    else {
        $netlogonStatus = 'Warning'
    }

    Add-CheckResult -Check 'Netlogon service' -Status $netlogonStatus -Details $netlogon.Status.ToString()
}

Write-Host ''
$results | Format-Table -AutoSize -Wrap

$passCount = @($results | Where-Object Status -eq 'Pass').Count
$failCount = @($results | Where-Object Status -eq 'Fail').Count
$warningCount = @($results | Where-Object Status -eq 'Warning').Count
$skippedCount = @($results | Where-Object Status -eq 'Skipped').Count

Write-Host ''
Write-Host ('Summary: {0} passed, {1} failed, {2} warnings, {3} skipped.' -f `
    $passCount, $failCount, $warningCount, $skippedCount)

if ($failCount -gt 0) {
    exit 1
}

exit 0
