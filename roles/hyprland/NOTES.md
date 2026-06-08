# Hyprland Role Notes

## Email UI follow-ups

- The `email` role now installs a `mail-count` helper intended for a future
  Waybar `custom/mail` module.
- Future Hyprland wiring should keep the visual integration here:
  - a Waybar `custom/mail` module using `~/.local/bin/mail-count`
  - a dedicated Waybar signal for mail refreshes after `notmuch new`
  - desktop notifications triggered from a future `goimapnotify` hook through
    `notify-send` or `swaync`
- No mail widget or notification rule is wired yet; this file is the ownership
  placeholder for that future UI work.
