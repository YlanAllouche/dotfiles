# Theme Pipeline

## Source of truth

Theme data is driven by shared variables, not by pywal runtime state.

The main inputs are:

- `appearance_theme_special`
- `appearance_theme_colors`
- `appearance_theme_recipe_colors`
- `appearance_colorwhirl_recipe_path`
- `appearance_default_resolutions`
- `appearance_additional_resolutions`

## Rendered outputs

The `appearance` role renders pywal-compatible files into `~/.cache/wal/`:

- `colors.json`
- `colors-hyprland.conf`
- `colors-waybar.css`
- `colors-kitty.conf`
- `colors-rofi-dark`
- `colors-rofi-light`
- `colors.sh`
- `omp.json`

This means apps can keep sourcing wal-style files even when pywal itself is not installed.

App-owned themed configs can consume the same shared palette. Current example:

- `linux_desktop` renders `zathura/zathurarc` from `appearance` values while still keeping a fallback file in the repo.

## Overriding theme values

Consumers can override individual colors directly:

```yml
appearance_theme_special:
  background: "#111111"
  foreground: "#f5f5f5"
  cursor: "#f5f5f5"

appearance_theme_colors:
  color0: "#111111"
  color1: "#e41c23"
  color2: "#60d394"
  color3: "#ffd97d"
  color4: "#5aa9e6"
  color5: "#c77dff"
  color6: "#7bdff2"
  color7: "#f5f5f5"
  color8: "#666666"
  color9: "#e41c23"
  color10: "#60d394"
  color11: "#ffd97d"
  color12: "#5aa9e6"
  color13: "#c77dff"
  color14: "#7bdff2"
  color15: "#ffffff"
```

## Wallpaper generation

When `appearance_generate_wallpapers` is enabled, wallpapers are generated on the controller with `colorwhirl` and then copied to the target.

Generated outputs land under:

- controller cache: `{{ lookup('env', 'HOME') }}/.cache/dotfiles-wallpapers/<profile>`
- target directory: `~/.local/share/wallpapers/generated/`

Two variants are produced for each resolution:

- `wallpaper-<resolution>.png`
- `wallpaper-themed-<resolution>.png`

## Consumer-side control

Typical consumer overrides:

- disable pywal package installation but still copy static wal outputs
- swap `appearance_colorwhirl_recipe_path`
- add machine-specific resolutions
- disable target-side `colorwhirl` or `matugen` installation
