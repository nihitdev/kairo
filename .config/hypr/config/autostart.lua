-- ╭──────────────────────────────────────────────╮
-- │ Autostart                                    │
-- ╰──────────────────────────────────────────────╯

hl.on("hyprland.start", function()
    -- Export the Wayland session for D-Bus activated applications.
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    )

    -- The installer supplies this override when Kairo Shell is selected.
    local has_bar, bar = pcall(require, "config.bar")
    hl.exec_cmd(has_bar and bar or 'pgrep -u "$(id -u)" -x waybar >/dev/null || waybar')

    -- Store copied text and images for the clipboard launcher.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- battery-guardian holds its own flock to prevent duplicate watchers.
    hl.exec_cmd('[ ! -x "$HOME/.local/bin/battery-guardian" ] || "$HOME/.local/bin/battery-guardian"')

    -- Session daemons.
    for _, daemon in ipairs({
        "hyprpaper",
        "hypridle",
        "swaync",
        "nm-applet",
    }) do
        hl.exec_cmd(
            'pgrep -u "$(id -u)" -x ' .. daemon .. " >/dev/null || " .. daemon
        )
    end
end)
