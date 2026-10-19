local M = "SUPER"
local HOME = os.getenv("HOME")
local SCRIPTS = HOME .. "/.config/hypr/scripts/"

-- ╭──────────────────────────────────────────────╮
-- │ Applications                                 │
-- ╰──────────────────────────────────────────────╯

hl.bind(M .. " + Return", hl.dsp.exec_cmd(P.terminal))
hl.bind(M .. " + B",      hl.dsp.exec_cmd(P.browser))
hl.bind(M .. " + E",      hl.dsp.exec_cmd(P.fileManager))
hl.bind(M .. " + Space",  hl.dsp.exec_cmd(P.launcher))
hl.bind(M .. " + G",      hl.dsp.exec_cmd(P.videoEditor))
hl.bind(M .. " + N",      hl.dsp.exec_cmd(P.editor))

-- ╭──────────────────────────────────────────────╮
-- │ Window Management                            │
-- ╰──────────────────────────────────────────────╯

hl.bind(M .. " + W", hl.dsp.window.close())
hl.bind(M .. " + P", hl.dsp.window.pseudo())

-- Vim-style focus.
hl.bind(M .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(M .. " + K", hl.dsp.focus({ direction = "up" }))

-- SUPER + L is intentionally used for layout switching.
hl.bind(M .. " + L", hl.dsp.exec_cmd(SCRIPTS .. "toggle-layout.sh"))

-- Arrow-key focus.
hl.bind(M .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(M .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Mouse window control.
hl.bind(M .. " + mouse:272", hl.dsp.window.drag())
hl.bind(M .. " + mouse:273", hl.dsp.window.resize())

-- ╭──────────────────────────────────────────────╮
-- │ Workspaces                                   │
-- ╰──────────────────────────────────────────────╯

for i = 1, 9 do
    hl.bind(M .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(M .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(M .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Scratch workspace.
hl.bind(M .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(
    M .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special:magic" })
)

-- Scroll through workspaces.
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ╭──────────────────────────────────────────────╮
-- │ Screenshots                                  │
-- ╰──────────────────────────────────────────────╯

hl.bind("ALT + Z",       hl.dsp.exec_cmd(SCRIPTS .. "screenshot.sh region"))
hl.bind("PRINT",         hl.dsp.exec_cmd(SCRIPTS .. "screenshot.sh region"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "screenshot.sh full"))

-- ╭──────────────────────────────────────────────╮
-- │ Audio                                        │
-- ╰──────────────────────────────────────────────╯

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true }
)

-- ╭──────────────────────────────────────────────╮
-- │ Brightness                                   │
-- ╰──────────────────────────────────────────────╯

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl --min-value=1 set 5%-"),
    { locked = true, repeating = true }
)

-- ╭──────────────────────────────────────────────╮
-- │ Media                                        │
-- ╰──────────────────────────────────────────────╯

hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)

-- ╭──────────────────────────────────────────────╮
-- │ Desktop Utilities                            │
-- ╰──────────────────────────────────────────────╯

hl.bind(
    M .. " + V",
    hl.dsp.exec_cmd(HOME .. "/.config/rofi/clipboard/clipboard.sh")
)

hl.bind(
    M .. " + ALT + Space",
    hl.dsp.exec_cmd(SCRIPTS .. "wallpaper-picker.sh")
)

hl.bind(
    M .. " + ALT + L",
    hl.dsp.exec_cmd(SCRIPTS .. "lock.sh")
)

-- Live wallpaper picker.

hl.bind(M .. " + CTRL + Space", hl.dsp.exec_cmd(SCRIPTS .. "live-wallpaper.sh"))

-- Everyday window controls. Existing shortcuts remain available.
hl.bind(M .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(M .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(M .. " + SHIFT + Space", hl.dsp.window.float())
hl.bind(M .. " + C", hl.dsp.window.center())
hl.bind(M .. " + Tab", hl.dsp.window.cycle_next({ next = true }))
hl.bind(M .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

for _, item in ipairs({
    { "left", "left", -40, 0 }, { "right", "right", 40, 0 },
    { "up", "up", 0, -40 }, { "down", "down", 0, 40 },
}) do
    hl.bind(M .. " + SHIFT + " .. item[1], hl.dsp.window.move({ direction = item[2] }))
    hl.bind(M .. " + CTRL + " .. item[1],
        hl.dsp.window.resize({ x = item[3], y = item[4], relative = true }),
        { repeating = true })
end

hl.bind(M .. " + bracketleft", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + slash", hl.dsp.exec_cmd(SCRIPTS .. "keybinds.sh"))
hl.bind(M .. " + SHIFT + R", hl.dsp.exec_cmd(SCRIPTS .. "reload.sh"))
hl.bind(M .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd(SCRIPTS .. "screenshot.sh window"))
