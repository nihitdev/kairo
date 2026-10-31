#!/bin/sh

installed=$(grep -m1 -E '\[ALPM\] installed (filesystem|base) ' /var/log/pacman.log 2>/dev/null | cut -d']' -f1 | tr -d '[')

if [ -z "$installed" ]; then
    echo "Unknown"
    exit 0
fi

start=$(date -d "$installed" +%s) || exit 1
elapsed=$(( $(date +%s) - start ))

days=$((elapsed / 86400))
hours=$(((elapsed % 86400) / 3600))

printf '%d days, %d hours\n' "$days" "$hours"
