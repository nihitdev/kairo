#!/usr/bin/env bash
set -euo pipefail
config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT
if ! Hyprland --verify-config -c "$config" >"$log" 2>&1; then
    notify-send -u critical -a Hyprland 'Configuration rejected' "$(tail -n 12 "$log")"
    cat "$log" >&2
    exit 1
fi
hyprctl reload >/dev/null
errors="$(hyprctl configerrors)"
if [[ -n "${errors//[[:space:]]/}" ]]; then
    notify-send -u critical -a Hyprland 'Reload error' "$errors"
    exit 1
fi
notify-send -a Hyprland 'Configuration reloaded' 'All compositor settings validated.'
