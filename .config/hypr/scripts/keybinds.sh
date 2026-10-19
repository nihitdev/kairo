#!/usr/bin/env bash
set -euo pipefail
root="${XDG_CONFIG_HOME:-$HOME/.config}"
# This menu is a reference; selecting a row never executes it.
rofi -dmenu -i -p 'Shortcuts' \
    -theme "$root/rofi/style-1.rasi" \
    -theme-str 'window { width: 760px; } listview { lines: 12; } element-icon { enabled: false; }' \
    < "$root/hypr/shortcuts.txt" > /dev/null || true
