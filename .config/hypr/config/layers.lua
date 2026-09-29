-- ╭──────────────────────────────────────────────╮
-- │ Layer Rules                                  │
-- ╰──────────────────────────────────────────────╯

-- Blur only surfaces that actually benefit from transparency.
for _, namespace in ipairs({
    "waybar",
    "swaync-control-center",
    "rofi",
    "swaync-notification-window",
}) do
    hl.layer_rule({
        name = namespace .. "-glass",
        match = {
            namespace = "^" .. namespace .. "$",
        },

        blur = true,
        ignore_alpha = 0.20,
    })
end
