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

# Shadern använder `uniform float time` (animerat regn), och Hyprland vägrar
# då ladda den om inte debug:damage_tracking är 0 (= rita om hela skärmen
# varje bildruta). Det kostar lite batteri, så damage tracking slås på igen
# (2 = standard, full) när regnet stängs av.
set_shader() {
    # Två separata anrop i rätt ordning (en lua-tabell har ingen garanterad
    # ordning): damage tracking av FÖRE shadern laddas, och på igen EFTER att
    # den tagits bort.
    if [ -n "$1" ]; then
        hyprctl eval "hl.config({ debug = { damage_tracking = 0 } })" >/dev/null
        hyprctl eval "hl.config({ decoration = { screen_shader = \"$1\" } })" >/dev/null
    else
        hyprctl eval "hl.config({ decoration = { screen_shader = \"\" } })" >/dev/null
        hyprctl eval "hl.config({ debug = { damage_tracking = 2 } })" >/dev/null
    fi
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
