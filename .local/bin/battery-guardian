#!/usr/bin/env bash

# Prefer the original BAT1, then detect laptops which expose BAT0 or another BAT.
BAT=${BATTERY_GUARDIAN_BATTERY:-/sys/class/power_supply/BAT1}
INTERVAL=${BATTERY_GUARDIAN_INTERVAL:-15}
if [[ ! -r $BAT/capacity || ! -r $BAT/status ]]; then
    for candidate in /sys/class/power_supply/BAT*; do
        [[ -r $candidate/capacity && -r $candidate/status ]] || continue
        BAT=$candidate
        break
    done
fi
[[ -r $BAT/capacity && -r $BAT/status ]] || exit 0

# Hold the lock for this process's lifetime, including notification delivery.
# Repeated autostarts and manual launches cannot create duplicate watchers.
lock_dir=${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}
mkdir -p -- "$lock_dir" || exit 1
exec 9>"$lock_dir/battery-guardian.lock"
flock -n 9 || exit 0

warn20=false
warn10=false
warn5=false

while sleep "$INTERVAL"; do
    [[ -r "$BAT/capacity" && -r "$BAT/status" ]] || continue

    IFS= read -r capacity < "$BAT/capacity" || continue
    IFS= read -r status < "$BAT/status" || continue
    [[ $capacity =~ ^[0-9]{1,3}$ ]] || continue
    capacity=$((10#$capacity))
    ((capacity <= 100)) || continue

    # Reset warnings after plugging the charger in.
    if [[ "$status" == "Charging" || "$status" == "Full" ]]; then
        warn20=false
        warn10=false
        warn5=false
        continue
    fi

    [[ $status == "Discharging" ]] || continue

    if (( capacity <= 5 )) && [[ "$warn5" == false ]]; then
        notify-send -u critical -t 10000 \
            "󰂃 BATTERY CRITICAL — ${capacity}%" \
            "PLUG IN YOUR CHARGER 💀"

        warn5=true
        warn10=true
        warn20=true

    elif (( capacity <= 10 )) && [[ "$warn10" == false ]]; then
        notify-send -u critical -t 10000 \
            "󰁺 Battery very low — ${capacity}%" \
            "Charger. NOW."

        warn10=true
        warn20=true

    elif (( capacity <= 20 )) && [[ "$warn20" == false ]]; then
        notify-send -u normal -t 10000 \
            "󰁻 Battery low — ${capacity}%" \
            "Plug in soon 🔋"

        warn20=true
    fi
done
