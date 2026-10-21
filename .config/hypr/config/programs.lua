-- ╭──────────────────────────────────────────────╮
-- │ Programs                                     │
-- ╰──────────────────────────────────────────────╯

local HOME = os.getenv("HOME")
-- Check at launch time: Hyprland can reap os.execute() children before Lua waits.
-- The wrapper selects the patched Kitty; stock Kitty remains the fallback.
local TERMINAL = [[sh -c 'if [ -x "$HOME/.local/bin/kitty-smooth" ]; then exec "$HOME/.local/bin/kitty-smooth" "$@"; else exec kitty "$@"; fi' kitty-smooth]]

P = {
	terminal = TERMINAL,
	browser = "helium-browser",
	fileManager = "/home/nihitdev/.local/share/bin/bubble",
	launcher = '"' .. os.getenv("HOME") .. '/.config/rofi/launchers/launcher.sh"',
	editor = TERMINAL .. " nvim",
	videoEditor = "kdenlive",
}
