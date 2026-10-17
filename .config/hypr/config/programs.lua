-- ╭──────────────────────────────────────────────╮
-- │ Programs                                     │
-- ╰──────────────────────────────────────────────╯

local HOME = os.getenv("HOME")
local launcher = HOME .. "/.local/bin/kitty-smooth"
local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end
-- Keep shortcuts working when the optional launcher has not been installed.
local available = os.execute("test -x " .. quote(launcher))
local TERMINAL = (available == true or available == 0) and quote(launcher) or "kitty"

P = {
    terminal    = TERMINAL,
    browser     = "helium-browser",
    fileManager = "dolphin",
    launcher    = "\"" .. os.getenv("HOME") .. "/.config/rofi/launchers/launcher.sh\"",
    editor      = TERMINAL .. " nvim",
    videoEditor = "kdenlive",
}
