return {
    -- A restrained wallpaper-derived gradient keeps the focused window clear.
    active_border = {
        colors = {
            "rgba({{colors.primary.default.hex_stripped}}ff)",
            "rgba({{colors.secondary.default.hex_stripped}}ff)",
            "rgba({{colors.tertiary.default.hex_stripped}}ff)",
        },
        angle = 35,
    },
    inactive_border = "rgba({{colors.outline_variant.default.hex_stripped}}cc)",
    shadow = "rgba({{colors.shadow.default.hex_stripped}}66)",
}
