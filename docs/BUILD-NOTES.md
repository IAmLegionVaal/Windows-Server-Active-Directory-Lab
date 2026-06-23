# Implementation Notes

## Purpose

These notes document the Active Directory lab after it had been completed. Environment-specific values were generalized to prevent disclosure of credentials, internal names, and network information.

## Completed environment

| Component | Function | Final state |
|---|---|---|
| Windows Server | Domain controller | Installed and promoted |
| Active Directory Domain Services | Central directory and authentication | Operational |
| DNS | Internal domain name resolution | Operational |
| Windows client 1 | Domain member endpoint | Joined and tested |
| Windows client 2 | Domain member endpoint | Joined and tested |

## Server preparation

Before promoting the server, I completed the normal operating-system and networking preparation:

- Installed Windows Server.
- Assigned a clear server hostname.
- Configured a stable network address for the server.
- Confirmed local network connectivity.
- Installed operating-system updates.
- Confirmed that the time and date were correct.

A stable address was important because the domain clients depended on the domain controller for DNS and authentication.

## AD DS deployment

I used Server Manager to add the **Active Directory Domain Services** role and its management tools. After the role installation completed, I promoted the server to a domain controller and created a new forest for the lab.

The promotion process configured the directory database, SYSVOL, Kerberos authentication, and the DNS components required by the domain. After the restart, I signed in using the domain administrator context and confirmed that the AD DS management consoles were available.

## DNS configuration

The domain controller provided DNS for the Active Directory environment. I verified that the domain zone existed and that the required service records could be resolved.

The two client devices were configured to use the domain controller as their DNS server before they were joined. This allowed the clients to locate the domain controller and the Active Directory services advertised through DNS.

## Directory administration

I opened **Active Directory Users and Computers** to verify the domain and inspect the user and computer objects. I confirmed that the server and both joined endpoints were represented in the directory.

The lab included basic user and computer object administration. Exact account names and organizational details are intentionally not included in this public repository.

## Client domain joins

The domain join was completed separately on two Windows devices.

For each device, I:

1. Confirmed network connectivity to the domain controller.
2. Pointed the device's DNS configuration to the domain controller.
3. Verified that the domain name could be resolved.
4. Opened the Windows domain membership settings.
5. Entered the Active Directory domain name.
6. Supplied authorized domain credentials when prompted.
7. Restarted the device.
8. Signed in using a domain account.
9. Confirmed the computer object in Active Directory.

## Post-build checks

After both joins were complete, I checked:

- Domain membership on each endpoint
- DNS resolution of the domain and domain controller
- Communication between each endpoint and the server
- Domain-account sign-in
- Computer objects in Active Directory Users and Computers
- The client secure channel to the domain

## Information intentionally excluded

The following information was deliberately removed or generalized:

- Domain and forest names
- Administrator and test-user names
- Passwords
- Internal IPv4 addresses
- Server and endpoint hostnames
- Physical or virtual host details
- Any screenshot containing identifying information

This preserves the technical value of the project while keeping the original environment private.
