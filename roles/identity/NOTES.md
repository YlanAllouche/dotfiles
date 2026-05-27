# Identity Role Notes

## RBW config scaffold

`templates/rbw-config.json.j2` mirrors the current live config shape but is not
wired yet. The expected private values remain downstream or local-layer owned.

## rclone config scaffold

`templates/rclone.conf.j2` is a future single-file render target. This matches
rclone's native model better than pretending it supports multi-file includes.

Planned future input models to evaluate:

- one or more private fragments merged by Ansible into a single `rclone.conf`
- structured Ansible data (remote entries plus secret-bearing fields) rendered
  into one final INI-style config file

Current understanding:

- `rclone.conf` is INI-style, not TOML
- rclone naturally supports many remotes in one file via multiple `[remote]`
  sections
- `--config /path/to/file` selects a different single config file
- native multi-file include/merge support does not appear to be the standard
  rclone model
