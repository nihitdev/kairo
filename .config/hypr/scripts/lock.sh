#!/usr/bin/env bash
set -euo pipefail

# A missing wallpaper must never prevent locking the session.
pgrep -u "$(id -u)" -x hyprlock >/dev/null && exit 0
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
wall=''
if [[ -r $HOME/.cache/current-wallpaper ]]; then
    IFS= read -r wall < "$HOME/.cache/current-wallpaper" || true
fi
if [[ ! -f $wall && -f $config_root/hypr/current-wallpaper ]]; then
    wall=$(realpath -- "$config_root/hypr/current-wallpaper")
fi
if [[ ! -f $wall ]]; then
    wall=''
fi
# Escape sed replacement characters, including '&' in wallpaper directory names.
escaped=${wall//\\/\\\\}
escaped=${escaped//&/\\&}
escaped=${escaped//|/\\|}
sed "s|__WALLPAPER__|$escaped|g" \
    "$config_root/hyprlock/hyprlock.template.conf" \
    > "$config_root/hyprlock/hyprlock.conf"
exec hyprlock --config "$config_root/hyprlock/hyprlock.conf"
