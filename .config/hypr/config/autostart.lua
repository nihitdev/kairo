hl.on("hyprland.start", function()

    -- Status bar
    hl.exec_cmd("waybar")

    -- Idle daemon
    hl.exec_cmd("hypridle")

    -- Notifications
    hl.exec_cmd("swaync")

    -- Network tray
    hl.exec_cmd("nm-applet")

    -- Wallpaper
    hl.exec_cmd("hyprpaper")

    -- Desktop environment
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    )
end)
