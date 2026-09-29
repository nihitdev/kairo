-- ╭──────────────────────────────────────────────╮
-- │ Animations                                   │
-- ╰──────────────────────────────────────────────╯

-- Fast ease-out curve for responsive window movement.
hl.curve("easeOut", {
    type = "bezier",
    points = {
        { 0.16, 1.0 },
        { 0.30, 1.0 },
    },
})

-- Slightly softer workspace movement.
hl.curve("workspace", {
    type = "bezier",
    points = {
        { 0.25, 1.0 },
        { 0.50, 1.0 },
    },
})

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
    style = "popin 97%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
    style = "popin 97%",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4,
    bezier = "easeOut",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "workspace",
    style = "slide",
})
