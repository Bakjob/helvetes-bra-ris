#!/usr/bin/env bash
# Slår på/av regn-shadern (hypr/shaders/rain.glsl) live via hyprctl.
# Rör INGEN configfil - bara en runtime-inställning. Se vault/04-tema/regn-shader.md.
#
# Lua-config: `hyprctl keyword` fungerar inte längre ("keyword can't work with
# non-legacy parsers"), så värdet sätts med `hyprctl eval` + hl.config().
# Av/på avgörs av Hyprlands faktiska värde (getoption), inte bara markörfilen -
# filen talar bara om att regnet ska vara på, så att wallpaper-cycle.sh kan
# slå på det igen efter sin `hyprctl reload` (`toggle-rain.sh restore`).
STATE="$HOME/.cache/rain-shader-on"
SHADER="$HOME/.config/hypr/shaders/rain.glsl"

set_shader() {
    hyprctl eval "hl.config({ decoration = { screen_shader = \"$1\" } })" >/dev/null
}

if [ "${1:-}" = "restore" ]; then
    [ -f "$STATE" ] && set_shader "$SHADER"
    exit 0
fi

current=$(hyprctl getoption decoration:screen_shader 2>/dev/null | awk 'NR==1 {print $2}')

if [ "$current" = "$SHADER" ]; then
    set_shader ""
    rm -f "$STATE"
else
    set_shader "$SHADER"
    touch "$STATE"
fi
