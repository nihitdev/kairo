#!/usr/bin/env bash
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/hyprland-notifications"
status="$(timeout 2s qs ipc --path "$config" call notifications status 2>/dev/null)" || {
    printf '{"text":"","alt":"none","tooltip":"Notification center unavailable"}\n'
    exit 0
}

count="$(jq -r '.count // 0' <<<"$status")"
dnd="$(jq -r '.dnd // false' <<<"$status")"
if [[ $dnd == true ]]; then
    alt=$([[ $count -gt 0 ]] && printf 'dnd-notification' || printf 'dnd-none')
else
    alt=$([[ $count -gt 0 ]] && printf 'notification' || printf 'none')
fi

tooltip="Notifications: $count · Click to open · Right-click for DND"
[[ $dnd == true ]] && tooltip="Do Not Disturb · $count saved · Click to open · Right-click to disable"
jq -nc --arg text "$count" --arg alt "$alt" --arg tooltip "$tooltip" '{text:$text,alt:$alt,tooltip:$tooltip}'
