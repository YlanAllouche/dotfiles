# Dotfiles

Public Ansible-managed dotfiles and workstation setup.

This repo is meant to work on its own, while also staying usable as an upstream layer for a private or client-specific wrapper repo.

## Quick Start

1. Install the required Ansible collections:

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

2. Run the default profile:

```bash
ansible-playbook main.yml
```

The root `main.yml` currently defaults to the `hyprland` profile.

### macOS note when Galaxy is restricted

If your environment blocks Ansible Galaxy access but still allows GitHub, clone the AUR collection manually before running the macOS playbook:

```bash
mkdir -p ~/.ansible/collections/ansible_collections/kewlfft
git clone --depth=1 https://github.com/kewlfft/ansible-aur.git ~/.ansible/collections/ansible_collections/kewlfft/aur
git clone --depth=1 https://github.com/YlanAllouche/dotfiles.git && cd dotfiles && ansible-playbook playbooks/macos.yml
```

## Public Entry Points

- `main.yml`: friendly default entrypoint, currently equivalent to the public `hyprland` path.
- `playbooks/main.yml`: orchestration engine; loads base vars, selected profile vars, then runs the role graph.
- `playbooks/desktop-wayland.yml`: general GUI + Wayland baseline without compositor-specific ownership.
- `playbooks/hyprland.yml`: Hyprland-focused desktop path.
- `playbooks/macos.yml`: reusable public macOS baseline.

## Profiles

Public profiles live under `vars/profiles/`.

- `base`: mostly neutral defaults for direct engine usage.
- `desktop-wayland`: GUI baseline.
- `hyprland`: default desktop profile.
- `macos`: public macOS baseline.
- `custom`: intentionally empty so downstream repos can define the full profile themselves.

## Advanced Usage

Run a specific public scenario directly:

```bash
ansible-playbook playbooks/hyprland.yml
ansible-playbook playbooks/macos.yml
```

Drive the engine directly with a custom profile:

```bash
ansible-playbook playbooks/main.yml -e dotfiles_profile=custom
```

For inline role-only iteration examples such as `nvim` or `python_dev` on a remote test machine, see `docs/ansible-patterns.md`.

## Downstream Use

Private or client-specific repos are expected to import one of the public playbooks and override globals or role toggles there.

The intended contract is:

- public repo provides reusable roles and a small set of archetypal profiles
- downstream repo overrides vars, enables/disables roles, and carries secrets or client-specific notes
- `dotfiles_profile=custom` is the escape hatch when the full profile should live downstream

See `custom_profile_templates/` for copyable downstream starting points for:

- `hyprland`
- `macos`
- fully downstream-owned `custom`

More detail lives in `docs/playbook-interface.md`.
