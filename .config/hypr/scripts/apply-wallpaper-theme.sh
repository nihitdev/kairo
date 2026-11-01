#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
wallpaper="${1:-}"

if [[ -z "$wallpaper" ]]; then
    if [[ -f "$CONFIG_ROOT/hypr/current-live-wallpaper" ]]; then
        wallpaper="$CONFIG_ROOT/hypr/current-live-wallpaper"
    elif [[ -f "$CONFIG_ROOT/hypr/current-wallpaper" ]]; then
        wallpaper="$CONFIG_ROOT/hypr/current-wallpaper"
    elif [[ -r "$HOME/.cache/current-wallpaper" ]]; then
        IFS= read -r wallpaper < "$HOME/.cache/current-wallpaper" || true
    fi
fi

[[ -r "$wallpaper" ]] || {
    printf 'Matugen: wallpaper not found: %s\n' "${wallpaper:-<unset>}" >&2
    exit 1
}

case "${wallpaper,,}" in
    *.mp4|*.mkv|*.webm|*.mov)
        command -v ffmpeg >/dev/null || {
            printf 'Matugen: ffmpeg is required to sample a video wallpaper.\n' >&2
            exit 1
        }
        cache="${XDG_CACHE_HOME:-$HOME/.cache}/matugen"
        mkdir -p "$cache"
        frame="$cache/wallpaper-frame.png"
        ffmpeg -v error -y -sseof -1 -i "$wallpaper" -frames:v 1 -vf 'scale=640:-2' "$frame"
        wallpaper="$frame"
        ;;
esac

# Neovim watches the shared Base16-shaped Matugen palette and re-tints in place.
mkdir -p "$HOME/.cache/kairo"
matugen image "$wallpaper" --mode dark --prefer less-saturation --quiet

if command -v swaync-client >/dev/null; then
    swaync-client -rs >/dev/null 2>&1 || true
fi

# Apply colors to the running desktop pieces. Keep palette/config failures
# visible instead of silently leaving Hyprland on stale colors.
if command -v hyprctl >/dev/null && hyprctl -j monitors >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    errors="$(hyprctl configerrors 2>/dev/null || true)"
    if [[ -n "${errors//[[:space:]]/}" ]] && command -v notify-send >/dev/null; then
        notify-send -u critical -a Matugen 'Hyprland theme reload failed' "$errors" || true
    fi
fi

pkill -USR1 -u "$(id -u)" -x kitty 2>/dev/null || true
