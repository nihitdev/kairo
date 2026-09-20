#!/usr/bin/env bash
# Read the running compositor, including changes made outside the toggle script.
layout=$(hyprctl -j getoption general:layout 2>/dev/null | jq -r '.str // empty')
case "$layout" in
    scrolling) printf '󰖲 SCROLL\n' ;;
    dwindle) printf '󰕰 DWINDLE\n' ;;
    *) printf '󰕰 %s\n' "${layout:-UNKNOWN}" ;;
esac
