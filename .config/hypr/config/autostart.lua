-- Optional installer override: Kairo Shell replaces Waybar without rewriting this file.
local bar = "waybar"
local ok, override = pcall(require, "config.bar")
if ok then bar = override end

-- Session-start only: reloads must not create duplicate daemons.
hl.on("hyprland.start", function()
    -- Publish the session environment before D-Bus activated applications start.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    for _, daemon in ipairs({ "hyprpaper", "swaync", "hypridle", "waybar", "nm-applet" }) do
        if daemon ~= "waybar" or bar == "waybar" then
            hl.exec_cmd("pgrep -u \"$(id -u)\" -x " .. daemon .. " >/dev/null || " .. daemon)
        end
    end
    if bar ~= "waybar" then hl.exec_cmd(bar) end
end)
