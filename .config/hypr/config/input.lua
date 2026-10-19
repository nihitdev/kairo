-- ╭──────────────────────────────────────────────╮
-- │ Input                                        │
-- ╰──────────────────────────────────────────────╯

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        repeat_rate = 35,
        repeat_delay = 250,

        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
})

-- Three-finger horizontal workspace swipe.
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
