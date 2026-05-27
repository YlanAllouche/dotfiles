# Media Role Notes

## Unwired assets saved from first-draft

- `files/mpd/`
- `files/ncmpcpp/`
- `files/mpv/`
- `files/jellyfin-mpv-shim/reference/`

These are intentionally stored in the repo now but are not yet wired into the
role tasks.

## Future work

- Evaluate whether MPD/NCMPCPP should become a real optional media stack.
- Review whether `mpv-gif.lua`, `autocrop.lua`, and `autosub.lua` should be
  kept as in-repo references or replaced by fresher upstream versions when the
  MPV workflow is revisited.
- as well as the auto resume one if it's not build in
- Compare the two Jellyfin MPV Shim config variants (`classic` vs `mpv-ext`)
  before deciding what a future public baseline should look like.
- Consider optional media packages such as `glava` and `miniplayer` later,
  but do not wire them until the playback/UI story is clearer.
