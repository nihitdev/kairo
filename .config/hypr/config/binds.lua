local M = "SUPER"

-- ── Core apps ────────────────────────────────
hl.bind(M .. " + Return", hl.dsp.exec_cmd(P.terminal))
hl.bind(M .. " + B",      hl.dsp.exec_cmd(P.browser))
hl.bind(M .. " + E",      hl.dsp.exec_cmd(P.fileManager))
hl.bind(M .. " + Space",  hl.dsp.exec_cmd(P.launcher))
hl.bind(M .. " + G",      hl.dsp.exec_cmd(P.videoEditor))

-- Dev
hl.bind(M .. " + N", hl.dsp.exec_cmd(P.editor))

-- ── Window management ───────────────────────
hl.bind(M .. " + W", hl.dsp.window.close())
-- Clipboard history
hl.bind(
    M .. " + V",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/rofi/clipboard/clipboard.sh")
)
hl.bind(M .. " + P", hl.dsp.window.pseudo())

-- Focus: vim keys
hl.bind(M .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/toggle-layout.sh"))
hl.bind(M .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + J", hl.dsp.focus({ direction = "down" }))

-- Focus: arrow keys
hl.bind(M .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(M .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ── Workspaces ──────────────────────────────
for i = 1, 9 do
    hl.bind(M .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(M .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(M .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Scratch workspace
hl.bind(M .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(M .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse workspace switching
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window control
hl.bind(M .. " + mouse:272", hl.dsp.window.drag())
hl.bind(M .. " + mouse:273", hl.dsp.window.resize())

-- Screenshot
hl.bind("ALT + Z", hl.dsp.exec_cmd("flameshot gui"))

-- ── Media ───────────────────────────────────
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

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { locked = true, repeating = true }
)

hl.bind("XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true })

hl.bind("XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true })

hl.bind("XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true })

hl.bind("XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true })


-- ARCHNEMESIS wallpaper picker

-- ARCHNEMESIS wallpaper picker
hl.bind(M .. " + ALT + Space", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper-picker.sh"))

-- Lock screen
hl.bind(
    M .. " + ALT + L",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/lock.sh")
)
