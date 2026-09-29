#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    system)    exec kitty --class waybar-tui -e btop ;;
    audio)     exec kitty --class waybar-tui -e pulsemixer ;;
    network)   exec kitty --class waybar-tui -e nmtui ;;
    bluetooth) exec kitty --class waybar-tui -e bluetui ;;
    music)     exec kitty --class waybar-tui -e cava ;;
    calendar)  exec kitty --class waybar-tui -e calcurse ;;
    files)     exec kitty --class waybar-tui -e yazi ;;
    *)
        printf 'Usage: %s {system|audio|network|bluetooth|music|calendar|files}\n' "$0" >&2
        exit 2
        ;;
esac
