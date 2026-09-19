#!/usr/bin/env bash

dir="$HOME/.config/rofi"
theme="style-1"

rofi \
    -modi "clipboard:$HOME/.config/rofi/clipboard/cliphist-rofi" \
    -show clipboard \
    -theme "$dir/$theme.rasi"
