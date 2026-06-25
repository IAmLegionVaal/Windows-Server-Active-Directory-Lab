# Validation and Test Evidence

This document records the checks used to confirm that the completed lab was functioning as an Active Directory environment. Actual domain names, IP addresses and computer names are omitted.

Before running the examples, set the sanitized values to match the lab:

```powershell
$DomainName = 'corp.lab'
$DomainController = 'dc01.corp.lab'
```

## Server-side validation

### Confirm the installed AD DS role

```powershell
Get-WindowsFeature AD-Domain-Services
```

Expected result: the role is shown as installed.

### Confirm domain-controller information

```powershell
Get-ADDomainController
```

Expected result: the command returns the domain controller and domain information.

### Confirm the Active Directory domain

```powershell
Get-ADDomain
Get-ADForest
```

Expected result: both commands return the configured domain and forest without errors.

### Confirm DNS service status

```powershell
Get-Service DNS
```

Expected result: the DNS service reports a running state.

### Confirm domain DNS records

```powershell
Resolve-DnsName -Type SRV "_ldap._tcp.dc._msdcs.$DomainName"
```

Expected result: the query returns the domain-controller service record.

### Confirm computer objects

```powershell
Get-ADComputer -Filter * | Select-Object Name,Enabled,DistinguishedName
```

Expected result: the domain controller and the two joined Windows devices are visible in Active Directory.

## Client-side validation

The following checks were performed on each joined Windows device.

### Confirm the computer is domain joined

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name,Domain,PartOfDomain
```

Expected result: `PartOfDomain` is `True`, and the domain field shows the Active Directory domain.

### Confirm the current sign-in context

```powershell
whoami.exe
```

Expected result: the output uses the `DOMAIN\username` format when signed in with the domain account.

### Confirm DNS client configuration

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

Expected result: the active network adapter uses the domain controller as its DNS server.

### Confirm name resolution

```powershell
Resolve-DnsName -Name $DomainName
Resolve-DnsName -Name $DomainController
```

Expected result: both names resolve successfully through the internal DNS service.

### Discover a domain controller

```powershell
& nltest.exe "/dsgetdc:$DomainName"
if ($LASTEXITCODE -ne 0) {
    throw "Domain-controller discovery failed with exit code $LASTEXITCODE."
}
```

Expected result: Windows locates the domain controller and displays its site and service details.

### Test the secure channel

Run this only on a domain-joined member workstation or member server, not on a domain controller:

```powershell
$SecureChannelHealthy = Test-ComputerSecureChannel -Verbose
if (-not $SecureChannelHealthy) {
    throw 'The domain secure channel validation failed.'
}
```

Expected result: the command returns `True`.

### Review domain membership

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name,Domain,PartOfDomain
```

Expected result: `PartOfDomain` is `True` and `Domain` matches `$DomainName`.

## Connectivity checks

```powershell
$RequiredPorts = @(
    @{ Port = 53;  Service = 'DNS' }
    @{ Port = 88;  Service = 'Kerberos' }
    @{ Port = 389; Service = 'LDAP' }
    @{ Port = 445; Service = 'SMB' }
)

$ConnectivityResults = foreach ($RequiredPort in $RequiredPorts) {
    $Test = Test-NetConnection -ComputerName $DomainController `
        -Port $RequiredPort.Port -WarningAction SilentlyContinue

    [pscustomobject]@{
        DomainController = $DomainController
        Service          = $RequiredPort.Service
        Port             = $RequiredPort.Port
        Reachable        = $Test.TcpTestSucceeded
    }
}

$ConnectivityResults | Format-Table -AutoSize

if ($ConnectivityResults.Reachable -contains $false) {
    throw 'One or more required domain-controller ports were unreachable.'
}
```

These checks validate TCP access to common services used by DNS, Kerberos, LDAP and SMB. They do not replace application-layer service testing.

## Final outcome

The lab passed the core validation criteria:

- The server operated as a domain controller.
- AD DS and DNS were available.
- Both Windows endpoints were members of the domain.
- Domain DNS resolution worked.
- The clients could locate the domain controller.
- Domain authentication succeeded.
- Both endpoint computer accounts were present in Active Directory.

A read-only helper script is available at [`scripts/Test-ADLab.ps1`](../scripts/Test-ADLab.ps1) for repeating the client-side checks.
