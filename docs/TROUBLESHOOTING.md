# Troubleshooting Reference

This reference summarizes the main checks for common Active Directory lab issues. It is written for a small Windows Server domain with Windows client devices.

## Client could not find the domain

### Likely causes

- The client was using a public DNS server or the router for DNS.
- The domain controller was offline or unreachable.
- The domain name was entered incorrectly.
- Required DNS service records were unavailable.
- The client and server were on different or incorrectly configured networks.

### Checks

```powershell
ipconfig /all
Resolve-DnsName <domain-name>
Resolve-DnsName -Type SRV "_ldap._tcp.dc._msdcs.<domain-name>"
Test-NetConnection <domain-controller-name> -Port 53
```

### Resolution approach

1. Set the client's preferred DNS server to the domain controller.
2. Run `ipconfig /flushdns`.
3. Run `ipconfig /registerdns` if appropriate.
4. Confirm that the DNS service is running on the domain controller.
5. Retry domain discovery with `nltest /dsgetdc:<domain-name>`.

## Domain join failed with a credentials error

### Checks

- Confirm that the username was entered in `DOMAIN\username` or `username@domain` format.
- Confirm that the account had permission to join a device.
- Check whether a computer object with the same name already existed.
- Confirm that the client's date and time were close to the domain controller's time.

### Useful commands

```powershell
w32tm /query /status
Get-Date
```

Kerberos authentication is time-sensitive, so a significant clock difference can prevent authentication.

## Client joined but domain sign-in failed

### Checks

```powershell
whoami
Test-ComputerSecureChannel -Verbose
nltest /sc_verify:<domain-name>
```

Also confirm that:

- The client was connected to the lab network.
- The user account was enabled.
- The correct domain was selected at the sign-in screen.
- DNS still pointed to the domain controller.

## Secure channel was broken

A broken secure channel can occur when the computer account password and the local machine state no longer match.

### Read-only test

```powershell
Test-ComputerSecureChannel -Verbose
```

### Repair example

```powershell
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)
```

The repair command changes system state and should only be run with appropriate domain credentials after confirming the cause.

## DNS worked by IP but not by hostname

This normally indicated a name-resolution problem rather than a general network problem.

### Checks

```powershell
ping <domain-controller-ip>
Resolve-DnsName <domain-controller-name>
Get-DnsClientServerAddress -AddressFamily IPv4
```

### Resolution approach

- Correct the client DNS server setting.
- Confirm the host and service records on the DNS server.
- Flush the client DNS cache.
- Verify that the correct DNS suffix was applied.

## Computer account did not appear where expected

Newly joined devices normally appear in the default **Computers** container unless they were redirected or pre-staged in another organizational unit.

### Checks

```powershell
Get-ADComputer -Identity <computer-name>
```

Search the full directory before attempting to join the device again.

## Firewall or port-related failures

Common ports involved in a basic Active Directory environment include:

| Port | Protocol | Purpose |
|---|---|---|
| 53 | TCP/UDP | DNS |
| 88 | TCP/UDP | Kerberos |
| 135 | TCP | RPC endpoint mapper |
| 389 | TCP/UDP | LDAP |
| 445 | TCP | SMB and SYSVOL access |
| 464 | TCP/UDP | Kerberos password operations |
| 636 | TCP | LDAPS when configured |
| 3268 | TCP | Global Catalog |

Example connectivity tests:

```powershell
Test-NetConnection <domain-controller-name> -Port 53
Test-NetConnection <domain-controller-name> -Port 88
Test-NetConnection <domain-controller-name> -Port 389
Test-NetConnection <domain-controller-name> -Port 445
```

## Practical lesson

The most important troubleshooting lesson from this lab was to verify DNS first. Active Directory uses DNS to locate domain controllers and services. Successful internet access or a successful ping by IP address does not prove that the client can discover and use the domain correctly.
