hl.window_rule({
    match = {
        class = "^(Rofi)$",
    },
    opacity = 0.82,
})

hl.window_rule({
    match = {
        class = "^(btop-float)$",
    },
    float = true,
    size = "900 600",
    center = true,
})

-- Ingen blur på notis-fönstret: swaync gör den ytan hög/full skärmhöjd för
-- att kunna stapla notiser, och Hyprlands blur täcker hela den layer-ytan —
-- inte bara det synliga kortet. `ignorezero` (som bara skulle blurra där
-- alpha > 0) stöds inte av den här lua-bindningen ("unknown field"), så
-- enklaste fixen är att inte blurra ytan alls här. Kontrollcentret nedan
-- är en fast, liten yta och har inte samma problem — behåller blur där.
hl.layer_rule({
    match = { namespace = "^(swaync-notification-window)$" },
    blur = false,
})

hl.layer_rule({
    match = { namespace = "^(swaync-control-center)$" },
    blur = true,
})

hl.layer_rule({
    match = { namespace = "^(wob)$" },
    blur = true,
})

hl.layer_rule({
    match = { namespace = "^(waybar)$" },
    blur = true,
})

hl.layer_rule({
    match = { namespace = "^(eww-dropdown)$" },
    blur = true,
})

