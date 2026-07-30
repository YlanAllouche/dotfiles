# Custom Profile Templates

Examples that can be copied into a downstream private or client-specific repo.

Each template:

- imports the public repo by default from `$DOTFILES_PUBLIC_REPO_DIR`
- falls back to `$HOME/workspaces/repos/github/YlanAllouche/dotfiles`
- includes a comment showing the equivalent simple relative import
- can define `dotfiles_roles` inline in the wrapper playbook for small cases
- auto-loads `vars/dotfiles.consumer.yml` when that file exists beside the wrapper playbook

Available starting points:

- `hyprland/`: reuse the public Hyprland archetype and override a few flags through `vars/dotfiles.consumer.yml`; includes a copyable `vars/mail-accounts.yml` example for the public `email_accounts` contract
- `linux-bitwarden/`: consumer-side standalone starter that keeps Bitwarden controller-side resolution scoped to the downstream wrapper and drives it from a single `vars/bitwarden.yml`
- `macos/`: reuse the public macOS archetype and override a few flags inline through `dotfiles_roles` in the wrapper playbook
- `custom/`: let the whole profile live downstream while still using the public engine, with a fuller scratch-style `vars/dotfiles.consumer.yml`
