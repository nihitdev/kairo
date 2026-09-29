#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/Screenshot_$(date '+%Y-%m-%d_%H-%M-%S').png"

case "${1:-region}" in
    region)
        geometry="$(slurp)" || exit 0
        grim -g "$geometry" "$FILE"
        ;;

    full)
        grim "$FILE"
        ;;

    *)
        printf 'Usage: %s {region|full}\n' "$0" >&2
        exit 2
        ;;
esac

wl-copy < "$FILE"

notify-send \
    -a Screenshot \
    "Screenshot captured" \
    "$(basename "$FILE") — saved + copied to clipboard"
