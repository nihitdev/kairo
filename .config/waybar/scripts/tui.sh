#!/usr/bin/env bash
set -euo pipefail

terminal=kitty
if [[ -x "$HOME/.local/bin/kitty-smooth" ]]; then
    terminal="$HOME/.local/bin/kitty-smooth"
fi

case "${1:-}" in
    system)    exec "$terminal" --class waybar-tui -e btop ;;
    audio)     exec "$terminal" --class waybar-tui -e pulsemixer ;;
    network)   exec "$terminal" --class waybar-tui -e nmtui ;;
    bluetooth) exec "$terminal" --class waybar-tui -e bluetui ;;
    music)     exec "$terminal" --class waybar-tui -e cava ;;
    calendar)  exec "$terminal" --class waybar-tui -e calcurse ;;
    files)     exec "$terminal" --class waybar-tui -e yazi ;;
    *)
        printf 'Usage: %s {system|audio|network|bluetooth|music|calendar|files}\n' "$0" >&2
        exit 2
        ;;
esac
