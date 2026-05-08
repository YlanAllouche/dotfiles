# Ansible Patterns

## Entry points

- `main.yml` is the friendly default public entrypoint.
- `playbooks/main.yml` is the reusable orchestration engine.
- `playbooks/desktop-wayland.yml`, `playbooks/hyprland.yml`, and `playbooks/macos.yml` are public scenario wrappers.
- `vars/profiles/` contains public profile-level presets.
- `docs/playbook-interface.md` describes the intended public-vs-downstream interface.

## Role-only iteration

Use an inline playbook when you want a fast feedback loop on one or two roles without creating a tracked wrapper playbook.

Current Arch test-machine pattern:

```bash
ansible-playbook -i inventory/remote-archtest.yml --limit archtest /dev/stdin <<'EOF'
- name: Apply nvim role only
  hosts: all
  gather_facts: true

  pre_tasks:
    - name: Normalize runtime user and platform variables
      ansible.builtin.set_fact:
        active_user: "{{ ansible_facts['user_id'] }}"
        active_home: "{{ '/home/' ~ ansible_facts['user_id'] }}"
        platform_family: "{{ 'macos' if ansible_facts['system'] == 'Darwin' else 'linux' }}"
        is_macos: "{{ ansible_facts['system'] == 'Darwin' }}"
        is_linux: "{{ ansible_facts['system'] == 'Linux' }}"
        is_wsl: "{{ ansible_facts['kernel'] is search('WSL') or ansible_facts['kernel'] is search('Microsoft') }}"
        is_archlinux: "{{ ansible_facts['distribution'] == 'Archlinux' }}"

    - name: Normalize runtime path variables
      ansible.builtin.set_fact:
        xdg_config_home: "{{ active_home }}/.config"
        xdg_data_home: "{{ active_home }}/.local/share"
        xdg_state_home: "{{ active_home }}/.local/state"
        xdg_cache_home: "{{ active_home }}/.cache"
        local_bin_dir: "{{ active_home }}/.local/bin"
        pip3_executable: pip3

    - name: Refresh pacman package databases on Arch
      become: true
      community.general.pacman:
        update_cache: true
      when: is_archlinux | bool

  tasks:
    - name: Apply nvim role
      ansible.builtin.include_role:
        name: nvim
EOF
```

To iterate on both editor roles, add `python_dev` to the same inline playbook:

```yaml
  tasks:
    - name: Apply nvim role
      ansible.builtin.include_role:
        name: nvim

    - name: Apply python_dev role
      ansible.builtin.include_role:
        name: python_dev
```

For macOS, copy the `Detect Homebrew prefix on macOS` and `Normalize package-manager helper paths` pre_tasks from `playbooks/main.yml` so `pip3_executable` resolves to the Homebrew-managed interpreter.

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
