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

For inline role-only remote iteration, see `docs/ansible-patterns.md`.

## Documentation Map

- `docs/playbook-interface.md`: public entrypoints, profile model, and downstream wrapper contract.
- `docs/ansible-patterns.md`: operational rules, inline playbook examples, package policy, and migration patterns.
- `docs/role-map.md`: role inventory and ownership boundaries.
- `docs/theme-pipeline.md`: theme source-of-truth values, rendered static outputs, and wallpaper generation flow.
- `docs/consumer-contracts.md`: secrets, private config, app-owned state, and consumer-side injection patterns.
- `custom_profile_templates/README.md`: copyable downstream wrapper examples.
- `personal-layer/README.md`: local private-layer scaffold and machine-specific override patterns.

## Downstream And Private Layers

- Public profiles live under `vars/profiles/`.
- `dotfiles_profile=custom` is the escape hatch when the full profile should live downstream.
- Downstream repos and local private layers are expected to carry secrets, machine-specific overrides, and app-private state.

See `docs/playbook-interface.md` for the architecture and `docs/consumer-contracts.md` for the private-value patterns.
