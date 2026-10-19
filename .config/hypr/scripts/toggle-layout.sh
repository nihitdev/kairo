#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/hypr/config/appearance.lua"
LOCK="${XDG_RUNTIME_DIR:?}/archnemesis-layout.lock"

# Ignore rapid repeated presses.
exec 9>"$LOCK"
flock -n 9 || exit 0

current="$(hyprctl -j getoption general:layout | jq -er '.str')"

case "$current" in
    dwindle)   next="scrolling" ;;
    scrolling) next="master" ;;
    master)    next="dwindle" ;;
    *)         next="dwindle" ;;
esac

# Persist the selected layout; restore it if verification fails.
backup="$(mktemp)"
cp -- "$CFG" "$backup"
trap 'rm -f "$backup"' EXIT
sed -i -E \
    's/layout = "(dwindle|scrolling|master)"/layout = "'"$next"'"/' \
    "$CFG"

if ! Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" >/dev/null 2>&1; then
    cp -- "$backup" "$CFG"
    notify-send -u critical -a Hyprland 'Layout unchanged' 'Configuration validation failed; restored previous layout.'
    exit 1
fi

hyprctl reload >/dev/null

errors="$(hyprctl configerrors)"

if [[ -n "${errors//[[:space:]]/}" ]]; then
    cp -- "$backup" "$CFG"
    hyprctl reload >/dev/null
    notify-send -a Hyprland \
        "Layout configuration error" \
        "$errors"
    exit 1
fi

# Refresh the Waybar layout module.
pkill -RTMIN+8 -u "$(id -u)" -x waybar 2>/dev/null || true

notify-send \
    -a Hyprland \
    -h string:x-canonical-private-synchronous:hyprland-layout \
    "Layout changed" \
    "${next^}"
