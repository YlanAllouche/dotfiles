# Role Map

## Core roles

- `common`: shared directories and repo-level assumptions.
- `aur`: Arch AUR foundation and yay builder setup.
- `identity`: machine identity, git identity, rbw/pass/rclone slots, safe identity scaffolding.
- `appearance`: static theme outputs, pywal-compatible files, wallpaper generation, matugen/colorwhirl integration.
- `shell`: zsh, antidote, oh-my-posh wiring, shell snippets, shell helpers.
- `tty`: tmux, tmux-sessionizer, CLI helpers, optional gh/glab/newsboat/neofetch/pywal.
- `python_dev`: Python tooling, virtualenv/pip defaults, optional poetry.
- `ecmascript`: node/npm/pnpm, Playwright, frontend CLI helpers.
- `golang`: Go toolchain plus editor helpers.
- `tower`: Ansible and local automation tooling.
- `system_tty_login`: tty1 autologin and Hyprland start hook.

## Desktop roles

- `linux_desktop`: desktop-adjacent Linux apps, launchers, capture scripts, mpv, pacmixer, zathura.
- `hyprland`: Hyprland, hyprlock, hypridle, waybar, swaync, and Hyprland-specific helpers.
- `browser_base`: browser install plus the `browser` launcher script.
- `browser_personal`: tridactyl config, bitwarden toggle, tridactyl native host.
- `media`: local music and media helpers such as mpd/ncmpcpp and Jellyfin/Kodi scripts.

## Editor and workflow roles

- `nvim`: base Neovim install and imported config tree.
- `pkm`: Obsidian, obsidian.json, capturemd/dashboard-md, dataview/markdown overlays.
- `pim`: calendar, sync, task, and mail-adjacent PIM tooling.
- `llm`: opt-in LLM tooling such as OpenCode and Claude Code.
- `vscode`: editor install skeleton and later config ownership.

## Optional workflow roles

- `email`: public scaffolding for isync, msmtp, notmuch, neomutt.
- `r_lang`: R install, user library path, default packages.
- `java`: OpenJDK and Maven.
- `share_sync`: share root and sync client baseline.
- `peripherals`: currently dormant hardware-specific gestures and device notes.
- `cloud`: optional AWS/Fly/Terraform tooling.
- `oci`: optional podman/docker/k3-style container tooling.
- `android_dev`: Android platform tools, off by default.

## Current boundaries to refine later

- Some PKM-specific Neovim behavior still exists in the imported base Neovim tree and is then overlaid by `pkm`.
- Common language tooling can intentionally leak into `nvim` where that is the practical boundary.
- Browser, PKM, desktop, and shell scripts still need a second pass to reduce overlap and move more logic into clearly owned folders.
