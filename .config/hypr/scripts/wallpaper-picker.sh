#!/usr/bin/env bash
set -euo pipefail

WALLDIR="$HOME/Pictures/Wallpapers/CozyPixels/Catppuccin/Space & Cosmic"
CACHE="$HOME/.cache/current-wallpaper"
CURRENT="$HOME/.config/hypr/current-wallpaper"
THEME="$HOME/.config/rofi/wallpaper/wallpaper.rasi"

[[ -d "$WALLDIR" ]] || {
    notify-send -a Hyprpaper "Wallpaper directory not found" "$WALLDIR"
    exit 1
}

# Build the wallpaper list once.
mapfile -d '' -t walls < <(
    find "$WALLDIR" -type f \
        \( -iname '*.png' \
        -o -iname '*.jpg' \
        -o -iname '*.jpeg' \
        -o -iname '*.webp' \) \
        -print0
)

((${#walls[@]} > 0)) || {
    notify-send -a Hyprpaper "No wallpapers found" "$WALLDIR"
    exit 1
}

# Display filenames while passing the full image path as the Rofi icon.
selection="$(
    for wall in "${walls[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(basename "$wall")" "$wall"
    done |
        rofi -dmenu \
            -i \
            -show-icons \
            -p "󰸉  Wallpaper" \
            -theme "$THEME"
)" || exit 0

[[ -n "$selection" ]] || exit 0

wall=""

for candidate in "${walls[@]}"; do
    if [[ "$(basename "$candidate")" == "$selection" ]]; then
        wall="$candidate"
        break
    fi
done

[[ -n "$wall" ]] || exit 1

# Apply to every connected monitor.
mapfile -t monitors < <(
    hyprctl -j monitors | jq -r '.[].name'
)

((${#monitors[@]} > 0)) || exit 1

for monitor in "${monitors[@]}"; do
    result="$(
        hyprctl hyprpaper wallpaper "$monitor, $wall, cover"
    )"

    if [[ "$result" == *error* || "$result" == *Error* ]]; then
        notify-send -a Hyprpaper \
            "Could not apply wallpaper" \
            "$result"
        exit 1
    fi
done

# Persistent wallpaper for future sessions / lock screen.
ln -sfn -- "$wall" "$CURRENT"

mkdir -p "$(dirname "$CACHE")"
printf '%s\n' "$wall" > "$CACHE"
