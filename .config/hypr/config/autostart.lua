-- ╭──────────────────────────────────────────────╮
-- │ Autostart                                    │
-- ╰──────────────────────────────────────────────╯

hl.on("hyprland.start", function()
   hl.exec_cmd([[sh -c 'pgrep -f "[w]l-paste --type text --watch cliphist store" >/dev/null || exec wl-paste --type text --watch cliphist store']])
   hl.exec_cmd([[sh -c 'pgrep -f "[w]l-paste --type image --watch cliphist store" >/dev/null || exec wl-paste --type image --watch cliphist store']])
    -- Export the Wayland session for D-Bus activated applications.
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    )

    -- Start the selected wallpaper backend.
    hl.exec_cmd([[sh -c 'if [ -f "$HOME/.config/hypr/current-live-wallpaper" ]; then bash "$HOME/.config/hypr/scripts/live-wallpaper.sh" --restore; else pgrep -u "$(id -u)" -x hyprpaper >/dev/null || hyprpaper; fi']])

    -- Restore wallpaper-derived bar colors once per login.
    hl.exec_cmd('python3 "' .. os.getenv("HOME") .. '/.config/waybar/scripts/wallpaper-colors.py"')

    -- Hyprland notifications are owned by the lightweight Quickshell center.
    hl.exec_cmd([[sh -c 'qs -n -d -p "$HOME/.config/quickshell/hyprland-notifications"']])

    -- Recover Waybar if it exits unexpectedly; the watchdog uses a runtime lock.
    hl.exec_cmd([[sh -c 'pgrep -u "$(id -u)" -f "[w]aybar-watchdog.sh" >/dev/null || exec "$HOME/.config/waybar/waybar-watchdog.sh"']])

    -- Session daemons.
    for _, daemon in ipairs({
        "hypridle",
        "nm-applet",
    }) do
        hl.exec_cmd(
            'pgrep -u "$(id -u)" -x ' .. daemon .. " >/dev/null || " .. daemon
        )
    end
    -- Low-battery warnings.
    hl.exec_cmd(
        'pgrep -u "$(id -u)" -f "$HOME/.local/bin/[b]attery-guardian" >/dev/null || "$HOME/.local/bin/battery-guardian"'
    )
end)
