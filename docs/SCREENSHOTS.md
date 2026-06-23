# Screenshot Checklist

Screenshots can strengthen the portfolio value of this repository, but they must be reviewed before upload. Do not expose passwords, public IP addresses, personal email addresses, license keys, or reusable credentials.

## Recommended evidence

Create an `images` folder and add sanitized screenshots using descriptive filenames.

| Suggested filename | Screenshot content | What it demonstrates |
|---|---|---|
| `01-server-manager-ad-ds.png` | Server Manager showing the AD DS role | The server role was installed |
| `02-ad-users-and-computers.png` | Active Directory Users and Computers console | The domain was operational |
| `03-dns-zone.png` | DNS Manager showing the internal zone | DNS integration was configured |
| `04-client-01-domain-membership.png` | First client system properties or PowerShell output | Client 1 was domain joined |
| `05-client-02-domain-membership.png` | Second client system properties or PowerShell output | Client 2 was domain joined |
| `06-computer-objects.png` | ADUC showing both client computer objects | Both endpoints were registered in AD |
| `07-domain-login.png` | Sanitized domain sign-in evidence | Domain authentication succeeded |
| `08-secure-channel-test.png` | `Test-ComputerSecureChannel` returning `True` | The client trust relationship worked |

## Example Markdown

After uploading the images, they can be added to the main README using:

```markdown
## Lab evidence

### Active Directory Users and Computers

![Active Directory Users and Computers](images/02-ad-users-and-computers.png)

### Domain-joined endpoints

![Client 1 domain membership](images/04-client-01-domain-membership.png)

![Client 2 domain membership](images/05-client-02-domain-membership.png)
```

## Redaction checklist

Before committing any screenshot, check for:

- Passwords or credential prompts
- Full personal names that should not be public
- Email addresses
- Public IP addresses
- Internal IP addresses that you prefer to keep private
- Real domain or company names
- Product keys and activation information
- Remote access IDs
- Browser bookmarks or open tabs
- Notifications containing personal information
- File paths containing personal usernames

The screenshots should show the technical result without exposing the original environment.
