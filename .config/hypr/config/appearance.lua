hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 6,
        border_size = 2,

        col = {
            active_border = "rgba(c4a7e7ff)",
            inactive_border = "rgba(393552ff)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "scrolling",
    },

    decoration = {
        rounding = 4,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 0.94,

        shadow = {
            enabled = true,
            range = 8,
            render_power = 4,
            color = "rgba(00000088)",
        },

        blur = {
            enabled = true,
            size = 12,
            passes = 4,
            ignore_opacity = true,
            vibrancy = 0.25,
        },
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
})
