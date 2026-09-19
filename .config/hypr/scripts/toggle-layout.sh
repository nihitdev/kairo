#!/usr/bin/env bash

CFG="$HOME/.config/hypr/config/appearance.lua"

if grep -q 'layout = "dwindle"' "$CFG"; then
    sed -i 's/layout = "dwindle"/layout = "scrolling"/' "$CFG"
    hyprctl reload
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send -a "Hyprland" "🌀 Layout Changed" "Scrolling mode ON 🚀✨"
else
    sed -i 's/layout = "scrolling"/layout = "dwindle"/' "$CFG"
    hyprctl reload
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send -a "Hyprland" "🧩 Layout Changed" "Dwindle mode ON 🔥🐧"
fi
