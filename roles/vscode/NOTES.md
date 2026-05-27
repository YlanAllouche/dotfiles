# VSCode Role Notes

This role currently installs the editor only. The config assets below are
prepared for manual evaluation before wiring them into the role.

## Candidate manual deployment assets

- `roles/vscode/files/settings.jsonc`
- `roles/vscode/files/extensions.txt`

## Current config source

- Started from the current local `Code - OSS` settings because they look more
  mature and less experimental than the raw first-draft snippets.
- Then selectively folded in low-risk settings from `first-draft/roles/vscode/`.

## Current live OSS settings still intentionally left out

- `r.lsp.debug = true`

This appears to be a debugging aid rather than a durable default.

## First-draft settings not yet carried into `settings.jsonc`

- hidden horizontal and vertical editor scrollbars
- hidden workbench status bar
- explicit zoom level
- SQL Language Server connection entries
- YAML schema path tied to a specific local extension checkout
- AtlasCode / Jira state blocks
- `r.plot.defaults.colorTheme`

These need manual review because they are either machine-specific, extension-
path-specific, or likely too personal for the public repo.

## First-draft extension notes not yet reflected in the current extension list

- GitLens
- VSCode Neovim
- Remote SSH / Remote Containers
- material-icon-theme / classic-icons / doticons
- SQLTools and SQLTools drivers
- Docker extension
- Todo Tree / Todo Highlight
- project management extensions
- shell format
- hadolint
- peacock
- GitHub Pull Requests and Issues
- CSS Peek
- standalone C tooling extension
- standalone Git extension
- Code Spell Checker
- Better Comments
- Colorize
- Indent Rainbow
- Output Colorizer
- Prettier
- AtlasCode
- R Debugger
- Jupyter extensions

These are the first things to evaluate manually before deciding what belongs in
the public role, in personal-layer, or nowhere.
