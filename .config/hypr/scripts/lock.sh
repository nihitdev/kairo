#!/usr/bin/env bash

WALL="$(cat "$HOME/.cache/current-wallpaper" 2>/dev/null)"

if [[ ! -f "$WALL" ]]; then
    WALL="$(find "$HOME/Pictures/wallpapers/catppuccin" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        | head -n1)"
fi

[[ -z "$WALL" ]] && exit 1

sed "s|__WALLPAPER__|$WALL|g" \
    "$HOME/.config/hyprlock/hyprlock.template.conf" \
    > "$HOME/.config/hyprlock/hyprlock.conf"

exec hyprlock --config "$HOME/.config/hyprlock/hyprlock.conf"
