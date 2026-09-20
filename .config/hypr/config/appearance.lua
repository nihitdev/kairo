hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,

        col = {
            active_border = "rgba(c4a7e7ff)",
            inactive_border = "rgba(393552ff)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 0.97,

        shadow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = "rgba(100d1c99)",
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            ignore_opacity = true,
            vibrancy = 0.12,
        },
    },

    -- Keep manual splits stable; scrolling columns fit two windows on this display.
    dwindle = {
        preserve_split = true,
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
