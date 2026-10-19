-- Subtle ease-out motion without bounce or large zoom effects.
hl.curve("easeOut", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.30, 1.0 } },
})
hl.curve("workspace", {
    type = "bezier",
    points = { { 0.25, 1.0 }, { 0.50, 1.0 } },
})

-- Separate timings: opening is soft, closing is quick, focus stays responsive.
for _, animation in ipairs({
    { "global",     3.0, "easeOut" },
    { "windows",    3.0, "easeOut" },
    { "windowsIn",  3.0, "easeOut", "popin 99%" },
    { "windowsOut", 2.0, "easeOut", "popin 99%" },
    { "fade",       2.0, "easeOut" },
    { "layers",     2.5, "easeOut" },
    { "workspaces", 3.5, "workspace", "slide" },
}) do
    hl.animation({
        leaf = animation[1],
        enabled = true,
        speed = animation[2],
        bezier = animation[3],
        style = animation[4],
    })
end
