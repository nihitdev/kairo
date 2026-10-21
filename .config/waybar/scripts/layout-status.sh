#!/usr/bin/env bash

if [[ -n "${MANGO_INSTANCE_SIGNATURE:-}" ]] && command -v mmsg >/dev/null; then
    layout=$(mmsg get all-monitors 2>/dev/null |
        jq -r '[.monitors[] | select(.active) | .layout_symbol][0] // empty')

    case "$layout" in
        T)  echo "󰕰 TILE" ;;
        S)  echo "󰖲 SCROLLER" ;;
        CT) echo "󰕰 CENTER TILE" ;;
        G)  echo "󰕰 GRID" ;;
        K)  echo "󰕰 DECK" ;;
        M)  echo "󰕰 MONOCLE" ;;
        VS) echo "󰖲 VERTICAL SCROLLER" ;;
        *)  echo "󰕰 ${layout:-MANGO}" ;;
    esac

elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    layout=$(hyprctl -j getoption general:layout 2>/dev/null |
        jq -r '.str // empty')

    case "$layout" in
        scrolling) echo "󰖲 SCROLL" ;;
        master)    echo "󰶮 MASTER" ;;
        dwindle)   echo "󰕰 DWINDLE" ;;
        *)         echo "󰕰 ${layout:-HYPRLAND}" ;;
    esac

elif [[ "${XDG_CURRENT_DESKTOP,,}" == *sway* ]]; then
    echo "󰕰 SWAY"

else
    echo "󰕰 UNKNOWN"
fi
