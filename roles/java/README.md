# Java Role

This role turns the base Neovim config into an opt-in Java IDE layer.

## Scope

- installs `mise` and `maven`
- selects and installs the pinned Java and Gradle toolchains
- refreshes Gradle toolchain discovery from the `mise` installs
- installs the Java debug/test bundle helper jars for `nvim-jdtls`
- overlays the Java-specific Neovim files on top of the base `nvim` role

## Public vs local configuration

The public repo only ships the generic mechanism.

Repository-specific bootstrap rules belong in a machine-local file:
- `~/.local/java-projects.lua`

That file is loaded by `lua/jdtls_env.lua` when present.

## Notes

- Java stays opt-in through `java_enabled`.
- The base Neovim layer detects Java support by the presence of `ftplugin/java.lua`.
- Environment-specific pieces such as private Maven credentials or corporate
  certificate directories remain documented and optional.
