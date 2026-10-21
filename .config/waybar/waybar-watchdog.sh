#!/usr/bin/env bash

# Keep the bar available if Waybar exits unexpectedly. The runtime lock makes
# repeated Hyprland startup events harmless and disappears automatically at logout.
set -u

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
exec 9>"$runtime_dir/kairo-waybar-watchdog.lock"
flock -n 9 || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
mkdir -p -- "$state_dir"
log_file="$state_dir/watchdog.log"
delay=2

while :; do
    started=$SECONDS
    waybar
    status=$?
    elapsed=$((SECONDS - started))

    if [[ -f $log_file ]] && (( $(stat -c %s "$log_file") > 1048576 )); then
        mv -f -- "$log_file" "$log_file.old"
    fi
    printf '%s Waybar exited with status %d after %ds; restarting in %ds\n' \
        "$(date --iso-8601=seconds)" "$status" "$elapsed" "$delay" >> "$log_file"

    (( elapsed >= 60 )) && delay=2
    sleep "$delay"
    (( delay < 30 )) && delay=$((delay * 2))
done
