#!/usr/bin/env bash
set -euo pipefail

class="kairo-scratchpad"
workspace="magic"

if hyprctl -j clients | jq -e --arg class "$class" 'any(.[]; .class == $class)' >/dev/null; then
    exec hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$workspace\")"
fi

# A newly created special workspace is hidden by default. Reveal it before
# launching so the window rule places the first Kitty window somewhere visible.
if ! hyprctl -j monitors | jq -e --arg name "special:$workspace" \
    'any(.[]; .specialWorkspace.name == $name)' >/dev/null; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$workspace\")"
fi

if [[ -x "$HOME/.local/bin/kitty-smooth" ]]; then
    exec "$HOME/.local/bin/kitty-smooth" --class "$class" --title "Scratchpad"
fi

exec kitty --class "$class" --title "Scratchpad"
