hl.layer_rule({
    name = "waybar-glass",
    match = {
        namespace = "^waybar$",
    },

    blur = true,
    ignore_alpha = 0.20,
})

hl.layer_rule({
    name = "swaync-glass",
    match = {
        namespace = "^swaync-control-center$",
    },

    blur = true,
    ignore_alpha = 0.20,
})

-- Blur only the visible launcher/notification surfaces, not transparent margins.
for _, namespace in ipairs({ "rofi", "swaync-notification-window" }) do
    hl.layer_rule({
        name = namespace .. "-glass",
        match = { namespace = "^" .. namespace .. "$" },
        blur = true,
        ignore_alpha = 0.20,
    })
end
