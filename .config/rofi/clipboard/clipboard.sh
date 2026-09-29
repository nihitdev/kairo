#!/usr/bin/env bash
set -euo pipefail

exec rofi \
    -modi "clipboard:$HOME/.config/rofi/clipboard/cliphist-rofi" \
    -show clipboard \
    -theme "$HOME/.config/rofi/style-1.rasi"
