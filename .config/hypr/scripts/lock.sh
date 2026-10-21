#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE="$HOME/.cache/current-wallpaper"
CURRENT="$CONFIG_ROOT/hypr/current-wallpaper"
TEMPLATE="$CONFIG_ROOT/hyprlock/hyprlock.template.conf"
CONFIG="$CONFIG_ROOT/hyprlock/hyprlock.conf"

# Never launch multiple lock screens.
pgrep -u "$(id -u)" -x hyprlock >/dev/null && exit 0

wall=""

# Keep a stable path so even direct `hyprlock` launches follow wallpaper changes.
if [[ -f "$CURRENT" ]]; then
    wall="$CURRENT"
elif [[ -r "$CACHE" ]]; then
    IFS= read -r wall < "$CACHE" || true
fi

# Locking must still work without a wallpaper.
[[ -f "$wall" ]] || wall=""

# Escape characters meaningful inside a sed replacement.
escaped="${wall//\\/\\\\}"
escaped="${escaped//&/\\&}"
escaped="${escaped//|/\\|}"

temporary="$(mktemp "$CONFIG.XXXXXX")"
trap 'rm -f -- "$temporary"' EXIT
sed "s|__WALLPAPER__|$escaped|g" "$TEMPLATE" > "$temporary"
mv -f -- "$temporary" "$CONFIG"

exec hyprlock --config "$CONFIG"
