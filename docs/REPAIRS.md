# Repairs and Remediation Performed

The completed Active Directory lab included corrective work when domain discovery and client sign-in checks did not initially produce the expected result.

## Repairs completed

- Corrected client DNS settings to use the internal domain DNS service.
- Cleared stale resolver information and repeated name-resolution checks.
- Corrected client time synchronization.
- Re-ran domain discovery after the network corrections.
- Corrected the affected computer-account relationship and repeated sign-in testing.
- Confirmed that both client computer objects were present and enabled.
- Re-tested domain sign-in and client-to-server communication.

The repaired environment was validated from the domain controller and both joined Windows clients.

**This was tested by me to be working. User experience may vary.**
