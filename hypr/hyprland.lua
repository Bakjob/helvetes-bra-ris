-- Hyprland-huvudconfig (lua). Konverterad från det gamla .conf-systemet med
-- hyprlang2lua 2026-09-13, se vault/03-felsokning/hyprland-lua-migration.md.
-- Resten av configen ligger i modulerna nedan (hypr/<namn>.lua).

require("monitors")
require("input")
require("keybinds")
require("rules")
require("autostart")

-- Snabb/snappy tempo (~150-200ms), rät kurva utan overshoot — se
-- vault/04-tema/design.md för resonemanget bakom bytet från easeOutCubic (~300ms)
hl.curve("snappy", { type = "bezier", points = { { 0.2, 0.9 }, { 0.3, 1 } } })
-- "easeOutBack"-stil overshoot — studsig känsla för nya fönster (2026-09-15, på
-- Jakobs begäran: långsammare + lite mer bouncy än standard-snappy)
hl.curve("bouncy", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
-- Mjuk, icke-studsig kurva för fullscreen-övergången (bara långsammare, inte bouncy)
hl.curve("smooth", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "bouncy",
    style = "popin 80%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "bouncy",
    style = "popin 80%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 6,
    bezier = "smooth",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 4,
    bezier = "default",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "snappy",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3,
    bezier = "snappy",
    style = "slide",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3,
    bezier = "snappy",
    style = "slidevert",
})

-- Kantfärger i egen fil (dynamiskt tema per bakgrund, se
-- vault/04-tema/dynamiskt-tema.md) - hyprctl reload räcker för att plocka
-- upp ändringar här, ingen omstart av hela Hyprland behövs.
local colors = require("colors")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 6,
        border_size = 1,
        layout = "dwindle",
        ["col.active_border"] = colors.active_border,
        ["col.inactive_border"] = colors.inactive_border,
    },
    decoration = {
        rounding = 18,
        active_opacity = 0.92,
        inactive_opacity = 0.62,
        shadow = {
            enabled = true,
            range = 12,
            render_power = 2,
            color = "rgba(00000055)",
        },
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
        },
    },
    animations = {
        enabled = true,
    },
    misc = {
        vrr = 1,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

