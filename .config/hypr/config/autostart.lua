-- ╭──────────────────────────────────────────────╮
-- │ Autostart                                    │
-- ╰──────────────────────────────────────────────╯

hl.on("hyprland.start", function()
	hl.exec_cmd(
		[[sh -c 'pgrep -f "[w]l-paste --type text --watch cliphist store" >/dev/null || exec wl-paste --type text --watch cliphist store']]
	)
	hl.exec_cmd(
		[[sh -c 'pgrep -f "[w]l-paste --type image --watch cliphist store" >/dev/null || exec wl-paste --type image --watch cliphist store']]
	)
	-- Export the Wayland session for D-Bus activated applications.
	hl.exec_cmd('"' .. os.getenv("HOME") .. '/.config/hypr/scripts/start-waybar.sh"')

	-- Start the selected wallpaper backend.
	hl.exec_cmd(
		[[sh -c 'if [ -f "$HOME/.config/hypr/current-live-wallpaper" ]; then bash "$HOME/.config/hypr/scripts/live-wallpaper.sh" --restore; else pgrep -u "$(id -u)" -x hyprpaper >/dev/null || hyprpaper; fi']]
	)

	-- Generate the shared wallpaper palette once per login.
	hl.exec_cmd('"' .. os.getenv("HOME") .. '/.config/hypr/scripts/apply-wallpaper-theme.sh"')

	-- Session daemons.
	for _, daemon in ipairs({
		"hypridle",
		"nm-applet",
        "swaync",
	}) do
		hl.exec_cmd('pgrep -u "$(id -u)" -x ' .. daemon .. " >/dev/null || " .. daemon)
	end
	-- Low-battery warnings.
	hl.exec_cmd(
		'pgrep -u "$(id -u)" -f "$HOME/.local/bin/[b]attery-guardian" >/dev/null || "$HOME/.local/bin/battery-guardian"'
	)
end)
