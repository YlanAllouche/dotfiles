#!/usr/bin/env sh

set -eu

is_battery_discharging() {
  for supply in /sys/class/power_supply/*; do
    [ -d "$supply" ] || continue
    [ -f "$supply/type" ] || continue

    if [ "$(cat "$supply/type")" != "Battery" ]; then
      continue
    fi

    status=$(cat "$supply/status" 2>/dev/null || printf '%s' "Unknown")
    if [ "$status" = "Discharging" ]; then
      return 0
    fi
  done

  return 1
}

lock_screen() {
  pidof hyprlock >/dev/null 2>&1 || hyprlock
}

usage() {
  printf '%s\n' "Usage: $0 dpms-off-if-not-discharging|lock-if-discharging|lock-if-not-discharging" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage

case "$1" in
  dpms-off-if-not-discharging)
    if ! is_battery_discharging; then
      hyprctl dispatch dpms off
    fi
    ;;
  lock-if-discharging)
    if is_battery_discharging; then
      lock_screen
    fi
    ;;
  lock-if-not-discharging)
    if ! is_battery_discharging; then
      lock_screen
    fi
    ;;
  *)
    usage
    ;;
esac
