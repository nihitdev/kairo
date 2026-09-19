#!/usr/bin/env bash

WALLDIR="$HOME/Pictures/wallpapers/catppuccin"

# Build Rofi entries:
# filename + thumbnail using Rofi's icon metadata.
selection="$(
    find "$WALLDIR" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0 |
    while IFS= read -r -d '' img; do
        name="$(basename "$img")"
        printf '%s\0icon\x1f%s\n' "$name" "$img"
    done |
    rofi -dmenu \
        -i \
        -show-icons \
        -p "󰸉  Wallpaper" \
        -theme "$HOME/.config/rofi/wallpaper/wallpaper.rasi"
)"

[[ -z "$selection" ]] && exit 0

# Find selected image.
wall="$(
    find "$WALLDIR" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -name "$selection" -print -quit
)"

[[ -z "$wall" ]] && exit 1

# Hyprpaper IPC.
hyprctl hyprpaper wallpaper "LVDS-1, $wall, cover"

# Remember current wallpaper.
mkdir -p "$HOME/.cache"
printf '%s\n' "$wall" > "$HOME/.cache/current-wallpaper"
