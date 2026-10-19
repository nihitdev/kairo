-- Utility windows stay manageable on the laptop display.
hl.window_rule({
    name = "desktop-utilities",
    match = { class = "^(waybar-tui|org.pulseaudio.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.70)", "(monitor_h*0.70)" },
})
