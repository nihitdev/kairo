-- ╭──────────────────────────────────────────────╮
-- │ Appearance                                   │
-- ╰──────────────────────────────────────────────╯

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
        layout = "scrolling",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 0.97,

        -- Lighter shadow than before.
        shadow = {
            enabled = true,
            range = 8,
            render_power = 2,
            color = "rgba(100d1c80)",
        },

        -- Keep the glass look without hammering the GPU.
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            ignore_opacity = true,
            vibrancy = 0.10,
        },
    },

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
