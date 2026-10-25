-- ╭──────────────────────────────────────────────╮
-- │ Appearance                                   │
-- ╰──────────────────────────────────────────────╯

local colors = require("config.colors")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,

        col = {
            active_border = colors.active_border,
            inactive_border = colors.inactive_border,
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        -- Lighter shadow than before.
        shadow = {
            enabled = true,
            range = 12,
            render_power = 2,
            color = colors.shadow,
        },

        -- Keep the glass look without hammering the GPU.
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            ignore_opacity = true,
            vibrancy = 0.10,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    -- Main window uses 60% of the width; new windows join the side stack.
    master = {
        mfact = 0.60,
        orientation = "left",
        new_status = "slave",
    },

    scrolling = {
        column_width = 0.5,
        follow_focus = true,
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
})
