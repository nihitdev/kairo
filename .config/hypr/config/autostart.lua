-- ╭──────────────────────────────────────────────╮
-- │ Autostart                                    │
-- ╰──────────────────────────────────────────────╯

hl.on("hyprland.start", function()
    hl.exec_cmd('pgrep -f "wl-paste --type text --watch cliphist store" >/dev/null || wl-paste --type text --watch cliphist store')
    hl.exec_cmd('pgrep -f "wl-paste --type image --watch cliphist store" >/dev/null || wl-paste --type image --watch cliphist store')
    -- Export the Wayland session for D-Bus activated applications.
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    )

    -- Session daemons.
    for _, daemon in ipairs({
        "hyprpaper",
        "hypridle",
        "waybar",
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
