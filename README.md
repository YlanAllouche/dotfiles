# Dotfiles

Public Ansible-managed dotfiles and workstation setup.

This repo works on its own, while also staying usable as an upstream layer for a private or client-specific wrapper repo.

## Quick Start

```bash
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook main.yml
```

Useful entrypoints:

- `main.yml`: friendly default entrypoint, currently the public `hyprland` path.
- `playbooks/main.yml`: orchestration engine.
- `playbooks/desktop-wayland.yml`: GUI + Wayland baseline.
- `playbooks/hyprland.yml`: Hyprland-focused desktop path.
- `playbooks/macos.yml`: reusable public macOS baseline.

## Local Apply

By default, this repo targets the current machine as the current user.

- `active_user` defaults to the current Ansible user.
- `active_home` defaults to that user's home directory.
- user config lands under that home directory.
- system-wide tasks use `become: true` only where needed.

Common local commands:

```bash
# Default public profile on the current machine.
ansible-playbook main.yml

# Apply a specific public entrypoint.
ansible-playbook playbooks/macos.yml
ansible-playbook playbooks/hyprland.yml

# Pass standard ansible-playbook flags.
ansible-playbook main.yml --check
ansible-playbook playbooks/macos.yml -K
```

## Consumers

This repo can be consumed in three main ways:

1. Run the public repo directly.
2. Import one of the public playbooks from a downstream wrapper repo.
3. Keep the full profile in a downstream wrapper with `dotfiles_profile=custom`.

Useful consumer starting points:

- `custom_profile_templates/README.md`: copyable downstream wrapper examples.
- `custom_profile_templates/hyprland/main.yml`: reuse the public Hyprland profile.
- `custom_profile_templates/macos/main.yml`: reuse the public macOS profile.
- `custom_profile_templates/custom/main.yml`: downstream-owned full profile.
- `personal-layer/README.md`: local private-layer scaffold used during development here.

Wrapper usage examples:

```bash
# Apply a downstream wrapper playbook.
ansible-playbook path/to/your-wrapper/main.yml

# Apply a tracked example wrapper from this repo.
ansible-playbook custom_profile_templates/hyprland/main.yml
```

For inline role-only remote iteration, see `docs/ansible-patterns.md`.

## Documentation Map

- `docs/playbook-interface.md`: public entrypoints, profile model, and downstream wrapper contract.
- `docs/ansible-patterns.md`: operational rules, inline playbook examples, package policy, and migration patterns.
- `docs/role-map.md`: role inventory and ownership boundaries.
- `docs/theme-pipeline.md`: theme source-of-truth values, rendered static outputs, and wallpaper generation flow.
- `docs/consumer-contracts.md`: secrets, private config, app-owned state, and consumer-side injection patterns.
- `custom_profile_templates/README.md`: copyable downstream wrapper examples, including the public mail-account contract example.
- `personal-layer/README.md`: local private-layer scaffold and machine-specific override patterns used during development here.

## Downstream And Private Layers

- Public profiles live under `vars/profiles/`.
- `dotfiles_profile=custom` is the escape hatch when the full profile should live downstream.
- Downstream repos and local private layers are expected to carry secrets, machine-specific overrides, and app-private state.

See `docs/playbook-interface.md` for the architecture and `docs/consumer-contracts.md` for the private-value patterns.
