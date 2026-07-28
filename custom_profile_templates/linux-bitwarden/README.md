# Linux Bitwarden Template

This downstream template keeps the public Linux desktop baseline on the current
`hyprland` profile, but shifts the example toward controller-side Bitwarden
lookups.

Use it when you want:

- one Bitwarden item per mail account
- public roles to keep their existing contract shape
- a downstream private layer that documents item names instead of tracked
  passwords

## Files

- `main.yml`: imports the public repo and points Ansible at one Bitwarden-backed
  vars file
- `vars/mail-accounts-explicit.yml`: literal, low-magic example
- `vars/mail-accounts-helper.yml`: helper-oriented local abstraction example

## Expected Bitwarden setup

The lookup runs on the Ansible controller.

- install the collection: `ansible-galaxy collection install community.general`
- install the official Bitwarden CLI where `ansible-playbook` runs
- authenticate and unlock before running the playbook

Example:

```bash
bw login
export BW_SESSION="$(bw unlock --raw)"
ansible-playbook main.yml
```

## Expected item shape

Each mail account uses one Bitwarden item named like `mail-account/<id>`.

The examples assume custom fields that mirror the public `email_accounts`
contract:

- `address`
- `realname`
- `maildir`
- `imap_host`
- `imap_port`
- `imap_user`
- `imap_password`
- `imap_auth_mechs`
- `imap_ssl_type`
- `smtp_host`
- `smtp_port`
- `smtp_user`
- `smtp_password`
- `smtp_tls_starttls`

The explicit example also derives `identity_git_name` and `identity_git_email`
from the primary mail account to show how the same Bitwarden item can satisfy an
existing public contract and downstream custom additions.
