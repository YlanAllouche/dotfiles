# Custom Profile Templates

Examples that can be copied into a downstream private or client-specific repo.

Each template:

- imports the public repo by default from `$DOTFILES_PUBLIC_REPO_DIR`
- falls back to `$HOME/workspaces/repos/github/YlanAllouche/dotfiles`
- includes a comment showing the equivalent simple relative import

Available starting points:

- `hyprland/`: reuse the public Hyprland archetype and override a few flags
- `macos/`: reuse the public macOS archetype and override a few flags
- `custom/`: let the whole profile live downstream while still using the public engine
