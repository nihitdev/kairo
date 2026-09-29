#!/usr/bin/env bash
set -euo pipefail

exec rofi \
    -show drun \
    -theme "$HOME/.config/rofi/style-1.rasi"
