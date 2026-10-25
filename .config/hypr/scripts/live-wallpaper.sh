#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/CozyPixels/Live Wallpapers/Wallpapers"
CURRENT="$HOME/.config/hypr/current-live-wallpaper"
RESTORING=false

if [[ "${1:-}" == "--restore" ]]; then
    [[ -f "$CURRENT" ]] || exit 0
    VIDEO="$(realpath -- "$CURRENT")"
    RESTORING=true
else
    [[ -d "$DIR" ]] || exit 1
    mapfile -d "" -t VIDEOS < <(find "$DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) -print0)
    ((${#VIDEOS[@]})) || { notify-send "No video wallpapers found"; exit 1; }
    THUMBS="$HOME/.cache/archnemesis/live-wallpapers"
    mkdir -p "$THUMBS"
    for video in "${VIDEOS[@]}"; do
        key="$(printf "%s" "$video" | sha256sum | cut -d" " -f1)"
        thumb="$THUMBS/$key.jpg"
        if [[ ! -s "$thumb" || "$video" -nt "$thumb" ]]; then
            ffmpeg -hide_banner -loglevel error -y -ss 2 -i "$video" -frames:v 1 -vf "scale=320:-2" "$thumb" || true
        fi
    done

    CHOICE="$(for video in "${VIDEOS[@]}"; do
        key="$(printf "%s" "$video" | sha256sum | cut -d" " -f1)"
        thumb="$THUMBS/$key.jpg"
        if [[ -s "$thumb" ]]; then
            printf "%s\0icon\x1f%s\n" "$(basename "$video")" "$thumb"
        else
            printf "%s\n" "$(basename "$video")"
        fi
    done | rofi -dmenu -i -show-icons -p "󰸉 Live Wallpaper" -theme "$HOME/.config/rofi/wallpaper/wallpaper.rasi")" || exit 0
    [[ -n "$CHOICE" ]] || exit 0
    VIDEO=""
    for video in "${VIDEOS[@]}"; do
        if [[ "$(basename "$video")" == "$CHOICE" ]]; then VIDEO="$video"; break; fi
    done
    [[ -f "$VIDEO" ]] || exit 1
fi

command -v mpvpaper >/dev/null || { notify-send "mpvpaper is not installed"; exit 1; }
pkill -u "$(id -u)" -x mpvpaper 2>/dev/null || true
pkill -u "$(id -u)" -x hyprpaper 2>/dev/null || true
mpvpaper -f -p -o "no-audio loop-file=inf hwdec=auto-safe" ALL "$VIDEO"
ln -sfn -- "$VIDEO" "$CURRENT"
if ! $RESTORING; then
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/apply-wallpaper-theme.sh" "$VIDEO"
    notify-send "Live wallpaper activated" "$(basename "$VIDEO")"
fi
