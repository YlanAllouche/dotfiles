# Browser Automation

`browser_base` owns the daily-driver browser entrypoint at `~/.local/bin/browser`.

Current defaults:

- macOS: Google Chrome launched with remote debugging enabled and wrapped by `~/Applications/DebugBrowser.app` so Launch Services can treat it as the default browser.
- Linux: Firefox launched with remote debugging enabled and advertised through `~/.local/share/applications/debug-browser.desktop` plus `xdg-settings`/`xdg-mime`.

The launcher is variable-driven rather than hardcoded. The main knobs are:

- `browser_base_browser_name`
- `browser_base_browser_command`
- `browser_base_remote_debugging_enabled`
- `browser_base_remote_debugging_host`
- `browser_base_remote_debugging_port`
- `browser_base_use_managed_profile`
- `browser_base_profile_dir`
- `browser_base_make_default_browser`
- `browser_base_browser_extra_args`

Protocol expectations:

- Chrome and Chromium-family targets expose Chrome DevTools Protocol.
- Firefox exposes WebDriver BiDi rather than CDP.

This means the user-facing flow stays the same across platforms while automation clients choose the protocol they know how to speak.

Operational notes:

- Re-running the role should be idempotent: file templates are compared before rewrite, Launch Services registration only runs when needed, and macOS/Linux default-browser commands only run when the current state differs.
- `browser_base` now runs early in `playbooks/main.yml` so browser registration/default-handler work happens before later desktop tooling.
- `roles/ecmascript/files/bin/dev-chrome` still exists as a separate helper for now and is a future cleanup candidate rather than the primary browser entrypoint.
