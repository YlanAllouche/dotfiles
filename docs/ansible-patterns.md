# Ansible Patterns

## Entry points

- `main.yml` is the friendly default public entrypoint.
- `playbooks/main.yml` is the reusable orchestration engine.
- `playbooks/desktop-wayland.yml`, `playbooks/hyprland.yml`, and `playbooks/macos.yml` are public scenario wrappers.
- `vars/profiles/` contains public profile-level presets.
- `docs/playbook-interface.md` describes the intended public-vs-downstream interface.

## Target model

- The default assumption is: run on the current machine for the current user.
- Remote targeting is handled with `active_user` and `active_home`.
- User-level config always lands under `{{ active_home }}`.
- System tasks use `become: true` only where needed.

## Public vs consumer

- Public, shareable defaults live in this repo.
- Machine-specific and secret-bearing overrides belong in the consuming playbook or repo.
- This repo should not assume how the consumer stores private data.

## Package policy

- Use native package modules directly.
- Arch packages use `community.general.pacman`.
- macOS packages use `community.general.homebrew` or `community.general.homebrew_cask`.
- AUR is the only deliberate abstraction point.

## AUR switch

- `aur_install_method: yay` uses `kewlfft.aur.aur` with a dedicated builder user.
- `aur_install_method: pacman` assumes the same package name is available through regular pacman, including your local cache/repo scenario.

## Folder-first configs

- Prefer copying full config directories when the application supports it.
- Current folder-based targets include:
  - `hypr/`
  - `waybar/`
  - `swaync/`
  - `kitty/`
  - `nvim/`

## Platform paths

- Keep most user config under `~/.config` across Linux and macOS.
- Put OS-specific path differences in shared vars instead of inventing a generic copy abstraction too early.
- Example already modeled in shared vars:
  - brew prefix
  - tridactyl config target
  - OpenCode global config target

## Hardware Contract

- `CPU_VENDOR` and `GPU_VENDOR` are the public interface between this repo and the infra layer.
- This repo should not install GPU drivers directly.
- The infra layer should provision the driver stack and, when needed, override the package contract variables such as `NVIDIA_REQUIRED_PACKAGE_GROUPS`.

## First-pass migration rule

- Prefer the live system over `first-draft/` when both exist.
- Use `first-draft/` mainly for:
  - missing configs not present on the current machine
  - older role ownership hints
  - examples of file layout and scenarios

## Theme policy

- Theme data should be source-of-truth variables.
- Pywal-compatible files are rendered outputs, not the source of truth.
- Targets should always receive a static wal-compatible theme so configs that source wal files do not fail even when pywal is disabled.
