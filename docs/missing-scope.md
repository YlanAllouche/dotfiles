# Missing Scope Inventory

This is the current shortlist of config areas, scripts, and packages that still look relevant to the dotfiles but are not fully modeled yet.

## Config Areas

- shell / tty:
  - `~/.gitconfig`
  - `~/.inputrc`
  - `~/.config/newsboat`
  - `~/.config/gh`
  - `~/.config/glab-cli`
  - `~/.config/bat`
  - `~/.config/btop`
- desktop / legacy desktop history:
  - `~/.config/gtk-3.0`
  - `~/.gtkrc-2.0`
  - `~/.xbindkeysrc`
  - `~/.Xdefaults`, `~/.Xresources`, `~/.xinitrc`, `~/.xserverrc`
  - `~/.config/libinput-gestures.conf`
  - `~/.config/touchegg`
- identity / sync:
  - `~/.config/rclone`
- editors / workflow:
  - `~/.config/obsidian`
  - `~/.config/ansible`
  - `~/.config/Code - OSS`
  - `~/.claude`, `~/.claude.json`
  - `~/.codex`

## Scripts

- tty / workflow:
  - `tmux_monitor.py`
  - `session-switch.sh`
  - `tasks`
  - `todo`
  - `journal`
  - `homeswitch`
  - `homesync`
- desktop:
  - `img-clip.sh`
  - `ocr-ss.sh`
  - `rec`
  - `generate_image`
- media / PKM:
  - `playlist-maker`
  - `jelly_play_yt`
  - `kodiyt`
  - `video-picker.py`
  - `refrshAllQueries.sh`
- frontend / dev:
  - `dev-chrome`

## Package Areas

- tty:
  - `gh`
  - `glab`
  - `newsboat`
  - `neofetch`
  - `tig`
  - `cloc`
  - `yq`
- desktop:
  - `zathura-pdf-mupdf`
  - `pacmixer`
  - `mpv`
  - `matugen-bin`
  - `calibre`
  - `koreader-bin`
- identity / sync:
  - `pass`
  - `pass-otp`
  - `rclone`
- PIM:
  - `afew`
  - `alot`
  - `gmailieer-git`
  - `goimapnotify`
  - `khal`
  - `todoman`
  - `vdirsyncer`
- development:
  - `ansible`
  - `playwright`
  - `terraform`
  - `flyctl`
  - `android-tools`

## Next High-Value Follow-Up

1. Finish curation of `~/.local/bin` and attach each stable script to a clear role.
2. Decide how much X11 / old desktop history to preserve as dormant config.
3. Expand the theme pipeline so app-owned templates consume a shared appearance data model.
4. Fill out the PIM and identity roles with real consumer-side config injection.
