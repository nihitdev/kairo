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
