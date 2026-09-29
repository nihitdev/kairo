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
    scrolling) next="dwindle" ;;
    *)         next="dwindle" ;;
esac

# Persist the selected layout.
sed -i -E \
    's/layout = "(dwindle|scrolling)"/layout = "'"$next"'"/' \
    "$CFG"

hyprctl reload >/dev/null

errors="$(hyprctl configerrors)"

if [[ -n "${errors//[[:space:]]/}" ]]; then
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
