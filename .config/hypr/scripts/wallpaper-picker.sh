#!/usr/bin/env bash
set -euo pipefail

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
)" || exit 0

[[ -z "$selection" ]] && exit 0

# Find selected image.
wall="$(
    find "$WALLDIR" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -name "$selection" -print -quit
)"

[[ -z "$wall" ]] && exit 1

# Hyprpaper IPC.
# Apply to every connected monitor instead of assuming a laptop output name.
mapfile -t monitors < <(hyprctl -j monitors | jq -r '.[].name')
(( ${#monitors[@]} > 0 )) || exit 1
for monitor in "${monitors[@]}"; do
    result=$(hyprctl hyprpaper wallpaper "$monitor, $wall, cover")
    if [[ "$result" == *error* || "$result" == *Error* ]]; then
        notify-send -a Hyprpaper 'Could not apply wallpaper' "$result"
        exit 1
    fi
done

# Hyprpaper reads this link at the next login.
ln -sfn -- "$wall" "$HOME/.config/hypr/current-wallpaper"

# Remember current wallpaper.
mkdir -p "$HOME/.cache"
printf '%s\n' "$wall" > "$HOME/.cache/current-wallpaper"
