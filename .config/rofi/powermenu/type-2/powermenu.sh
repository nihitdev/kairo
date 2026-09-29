#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/.config/rofi/powermenu/type-2"
THEME="$DIR/style-5.rasi"

shutdown=''
reboot=''
lock='󰌾'
suspend='󰒲'
logout='󰍃'

yes=''
no=''

uptime="$(uptime -p | sed 's/^up //')"

choice="$(
    printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
        rofi -dmenu \
            -p "Uptime: $uptime" \
            -mesg "A R C H N E M E S I S" \
            -theme "$THEME"
)" || exit 0

case "$choice" in
    "$lock")
        exec "$HOME/.config/hypr/scripts/lock.sh"
        ;;
    "$suspend"|"$logout"|"$reboot"|"$shutdown")
        confirm="$(
            printf '%s\n' "$yes" "$no" |
                rofi -dmenu \
                    -p "Confirmation" \
                    -mesg "Are you sure?" \
                    -theme "$THEME" \
                    -theme-str 'window { location: center; anchor: center; fullscreen: false; width: 350px; }' \
                    -theme-str 'mainbox { children: [ "message", "listview" ]; }' \
                    -theme-str 'listview { columns: 2; lines: 1; }' \
                    -theme-str 'element-text { horizontal-align: 0.5; }' \
                    -theme-str 'textbox { horizontal-align: 0.5; }'
        )" || exit 0

        [[ "$confirm" == "$yes" ]] || exit 0

        case "$choice" in
            "$suspend")  exec systemctl suspend ;;
            "$logout")   exec hyprctl dispatch exit ;;
            "$reboot")   exec systemctl reboot ;;
            "$shutdown") exec systemctl poweroff ;;
        esac
        ;;
esac
