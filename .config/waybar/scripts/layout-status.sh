#!/usr/bin/env bash

CFG="$HOME/.config/hypr/config/appearance.lua"

if grep -q 'layout = "scrolling"' "$CFG"; then
    printf '󰖲 SCROLL\n'
else
    printf '󰕰 DWINDLE\n'
fi
