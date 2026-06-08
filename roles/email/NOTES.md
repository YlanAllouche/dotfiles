# Email Role Notes

## Account contract

The public `email` role now expects account-specific data from the consuming
playbook or private layer through `email_accounts`.

Current supported fields:

- `id`
- `enabled`
- `primary`
- `address`
- `realname`
- `maildir`
- `signature`
- `signature_src`
- `sync.backend`
- `sync.enabled`
- `sync.folders`
- `sync.create`
- `sync.sync_mode`
- `sync.subfolders`
- `sync.imap.{host,port,user,password,auth_mechs,ssl_type}`
- `send.enabled`
- `send.smtp.{host,port,user,password,tls_starttls}`

The intended private example lives in `personal-layer/vars/mail-accounts.yml`.

Enabled IMAP accounts in this repo are rendered through `mbsync` only. Future
non-IMAP or provider-specific flows such as Gmail plus `lieer` should stay
disabled in the data model until they have dedicated wiring.

## Mail stack follow-ups

- `goimapnotify` is now part of the package baseline, but its account watcher
  config is still TODO. The intended steady-state is `goimapnotify` triggering
  `mbsync` plus `notmuch new`.
- `mail-count` is installed as a small notmuch-based helper for a future Waybar
  module.
- `alot` and `afew` are now treated as part of the email stack.
- `bower-mail` should stay commented out for now; its AUR build still needs a
  Makefile fix.
- `mblaze` is a future AUR candidate, but still intentionally opt-in.
- `mblaze-much` remains a manual or repo-based TODO until a packaging path is
  chosen.
