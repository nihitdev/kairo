#!/usr/bin/env bash
set -euo pipefail
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
config="$config_root/quickshell/wallpaper-picker"
if [[ "${1:-}" == "--rofi" ]]; then
    exec "$config_root/hypr/scripts/wallpaper-picker-rofi.sh"
fi
if qs ipc -p "$config" call picker close >/dev/null 2>&1; then
    exit 0
fi
exec qs -n -p "$config"
