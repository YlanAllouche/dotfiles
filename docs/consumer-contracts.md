# Consumer Contracts

This repo is public. Private values should be injected by the consuming playbook or local machine setup.

## Preferred patterns

1. App-native config files

- Best for: email, PIM, rclone, anything that naturally wants a config file.
- Strategy: the consuming playbook renders the real config to the target.

2. Role-specific target-side env files

- Best for: non-interactive helper scripts.
- Current supported paths:
  - `~/.config/dotfiles/env/llm.env`
  - `~/.config/dotfiles/env/media.env`

3. Shell snippets in `~/.local/config/shell/`

- Best for: interactive session variables.
- The public zsh config already sources every file in that folder.

4. Runtime secret retrieval through `rbw` or `pass`

- Best for: personal workflows where a command can fetch the value on demand.

5. systemd user environment

- Use only when an app or service truly needs it outside the shell/session path.

## Current role expectations

- `identity`: git name/email, rclone config, optional key distribution
- `email`: account-specific native config rendering
- `media`: Jellyfin env or runtime secret lookup
- `llm`: provider API keys and optional model overrides
- `pim`: native config rendering for khal/vdirsyncer/gmailieer

## Notes

- Avoid a single global env file.
- Prefer the smallest scope that matches the application.
- Keep consumer-side secret injection explicit and role-owned.
