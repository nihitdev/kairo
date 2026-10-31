#!/usr/bin/env bash
set -euo pipefail

layout=''
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then
    layout=$(hyprctl -j getoption general:layout 2>/dev/null |
        jq -r '.str // empty' 2>/dev/null) || layout=''
fi

case "$layout" in
    scrolling) printf '󰖲 SCROLL\n' ;;
    master)    printf '󰶮 MASTER\n' ;;
    dwindle)   printf '󰕰 DWINDLE\n' ;;
    *)         printf '󰕰 HYPRLAND\n' ;;
esac
