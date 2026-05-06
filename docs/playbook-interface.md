# Playbook Interface

## Goal

This repo should satisfy two audiences at once:

- someone cloning the public repo and trying it directly
- a downstream private or client-specific repo treating this one as an upstream layer

## Public Interface

- `main.yml` at repo root is the friendly default entrypoint.
- `playbooks/main.yml` is the orchestration engine.
- scenario playbooks under `playbooks/` are thin wrappers that select a public profile.
- public profile vars live under `vars/profiles/`.

The current public scenarios are:

- `main.yml` -> default `hyprland`
- `playbooks/desktop-wayland.yml`
- `playbooks/hyprland.yml`
- `playbooks/macos.yml`

## Profile Model

Profiles are meant to stay small in number and archetypal in scope.

Current intent:

- `desktop-wayland`: compositor-agnostic GUI baseline
- `hyprland`: desktop-wayland-like path focused on Hyprland
- `macos`: reusable public macOS baseline
- `custom`: public engine with no opinionated public profile data layered on top

This avoids creating a new public profile for every small variant.

## Variable Layering

The intended order is:

1. base globals from `group_vars/all.yml`
2. public profile vars from `vars/profiles/<profile>.yml`
3. downstream overrides from the importing private/client repo

Downstream repos should prefer overriding globals and role toggles instead of forking playbook logic.

## Downstream Expectations

A downstream repo is expected to:

- import one of the public playbooks
- override `dotfiles_profile` when needed
- set global vars such as `dotfiles_active_user`, `dotfiles_active_home`, or role-specific toggles
- keep private secrets, machine notes, and client-specific artifacts out of this public repo

The tracked `custom_profile_templates/` directory provides copyable examples for:

- reusing the public `hyprland` archetype
- reusing the public `macos` archetype
- using `dotfiles_profile=custom` so the full profile lives downstream

Use `dotfiles_profile=custom` when the downstream repo wants to define the full profile itself.

## Role Vars vs Profile Vars

Role defaults and role-owned vars stay where they already live.

Only profile-level selections belong in `vars/profiles/`.

This keeps the exported interface clear without moving existing role configuration structures unnecessarily.

## Current Boundaries

- Public repo should work directly on its own.
- Public repo may fetch public upstream scripts or repos when needed.
- Private/client repos should remain thin wrappers around this one instead of duplicating role graphs.

## Follow-up Areas

- refine the exact shape of the downstream wrapper repo once the public interface settles
- decide whether more public profiles are justified or whether downstream overlays are enough
- further reduce profile duplication where it becomes a maintenance burden
