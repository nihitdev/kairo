#!/usr/bin/env bash
set -euo pipefail

# Keep the selection persistent, as before. Serialize fast repeated key presses.
exec 9>"${XDG_RUNTIME_DIR:?}/archnemesis-layout.lock"
flock -n 9 || exit 0
CFG="$HOME/.config/hypr/config/appearance.lua"
current=$(hyprctl -j getoption general:layout | jq -er '.str')
case "$current" in
    dwindle) next=scrolling ;;
    *) next=dwindle ;;
esac

sed -i -E 's/layout = "(dwindle|scrolling)"/layout = "'"$next"'"/' "$CFG"
hyprctl reload >/dev/null
errors=$(hyprctl configerrors)
if [[ -n "${errors//[[:space:]]/}" ]]; then
    notify-send -a Hyprland 'Layout configuration error' "$errors"
    exit 1
fi
pkill -RTMIN+8 -u "$(id -u)" -x waybar 2>/dev/null || true
notify-send -a Hyprland -h string:x-canonical-private-synchronous:hyprland-layout \
    'Layout changed' "${next^}"
