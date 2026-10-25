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

matugen image "$wallpaper" --mode dark --prefer less-saturation --quiet

# Apply colors to the running desktop pieces. Each app keeps its own config
# and consumes the generated palette on reload or next launch.
hyprctl reload >/dev/null 2>&1 || true
if systemctl --user is-active --quiet waybar.service; then
    systemctl --user restart waybar.service || true
fi
pkill -USR1 -u "$(id -u)" -x kitty 2>/dev/null || true

qs_config="$CONFIG_ROOT/quickshell/hyprland-notifications"
if command -v jq >/dev/null && command -v qs >/dev/null; then
    qs_id="$(qs list --all --json 2>/dev/null | jq -r --arg path "$qs_config/shell.qml" '.[] | select(.config_path == $path) | .id' 2>/dev/null | head -n 1)"
    if [[ -n "$qs_id" ]]; then
        qs kill --id "$qs_id" >/dev/null 2>&1 || true
        for _ in {1..20}; do
            if ! qs list --all --json 2>/dev/null | jq -e --arg path "$qs_config/shell.qml" 'any(.[]; .config_path == $path)' >/dev/null 2>&1; then
                break
            fi
            sleep 0.1
        done
        qs -n -d -p "$qs_config" >/dev/null 2>&1
    fi
fi
