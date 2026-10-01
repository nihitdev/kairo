-- ╭──────────────────────────────────────────────╮
-- │              A R C H N E M E S I S           │
-- │                 Hyprland / Lua                │
-- ╰──────────────────────────────────────────────╯

require("config.programs")
require("config.env")
require("config.monitor")
require("config.appearance")
require("config.layers")
require("config.input")
require("config.animations")
require("config.binds")
require("config.autostart")

-- Let the tiling layout arrange windows instead of honoring app maximize requests.
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})
