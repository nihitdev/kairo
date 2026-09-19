#!/usr/bin/env bash

count="$(swaync-client -c 2>/dev/null || printf '0')"

if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
    printf '󰂚 %s\n' "$count"
else
    printf '󰂜\n'
fi
