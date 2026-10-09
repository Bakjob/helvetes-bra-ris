#!/usr/bin/env bash
# Slår på/av regn-shadern (hypr/shaders/rain.glsl) live via hyprctl.
# Rör INGEN configfil - bara en runtime-inställning. Se vault/04-tema/regn-shader.md.
#
#   toggle-rain.sh            av/på, stillastående regn (standard)
#   toggle-rain.sh animated   av/på, rinnande/animerat regn
#   toggle-rain.sh restore    slå på igen efter `hyprctl reload` om det var på
#
# Stillastående regn: samma shader men med `time` som konstant, genererad
# till ~/.cache. Utan `uniform float time` kan damage tracking vara på, så
# Hyprland ritar bara om det som ändras - i princip gratis.
# Animerat regn: kräver debug:damage_tracking = 0 (Hyprland vägrar annars
# ladda en shader som använder time), dvs hela skärmen ritas om 60 ggr/s.
# Mätt 2026-10-09: ~1,9 W extra (9,25 -> 11,1 W), GPU ~9 % -> ~29 %.
#
# Lua-config: `hyprctl keyword` fungerar inte, så värden sätts med
# `hyprctl eval` + hl.config(). Markörfilen innehåller läget (static/animated).
STATE="$HOME/.cache/rain-shader-on"
SHADER="$HOME/.config/hypr/shaders/rain.glsl"
STATIC_SHADER="$HOME/.cache/hypr-rain-static.glsl"

set_cfg() {
    hyprctl eval "hl.config({ $1 })" >/dev/null
}

enable() {
    if [ "$1" = "animated" ]; then
        # Två separata anrop i rätt ordning (en lua-tabell har ingen
        # garanterad ordning): damage tracking av FÖRE shadern laddas.
        set_cfg "debug = { damage_tracking = 0 }"
        set_cfg "decoration = { screen_shader = \"$SHADER\" }"
    else
        sed 's/^uniform float time;/const float time = 37.0; \/\/ stillastående variant, se toggle-rain.sh/' \
            "$SHADER" > "$STATIC_SHADER"
        set_cfg "decoration = { screen_shader = \"$STATIC_SHADER\" }"
    fi
    echo "$1" > "$STATE"
}

disable() {
    set_cfg "decoration = { screen_shader = \"\" }"
    set_cfg "debug = { damage_tracking = 2 }"
    rm -f "$STATE"
}

if [ "${1:-}" = "restore" ]; then
    [ -f "$STATE" ] && enable "$(cat "$STATE")"
    exit 0
fi

mode="${1:-static}"
current=$(hyprctl getoption decoration:screen_shader 2>/dev/null | awk 'NR==1 {print $2}')

case "$current" in
    *rain*.glsl) disable ;;
    *)           enable "$mode" ;;
esac
