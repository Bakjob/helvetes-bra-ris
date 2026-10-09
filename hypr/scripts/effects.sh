#!/usr/bin/env bash
# Skärmeffekter: sätter ihop en screen_shader av de valda effekterna i
# hypr/shaders/effects.glsl och laddar den live. Rör ingen configfil.
# Se vault/04-tema/skarmeffekter.md.
#
#   effects.sh toggle <id>   slå på/av en effekt
#   effects.sh off           stäng av alla
#   effects.sh apply         ladda om valda effekter (efter `hyprctl reload`)
#   effects.sh sync          skriv aktuellt läge till eww-galleriets fx_*-variabler
#
# Effekter (id: beskrivning, s = stillastående/gratis, r = rörlig/~2 W):
#   grade s, evening s, groundfog s, grain s, frost s, rain s,
#   rain_anim r, driftfog r, leaves r, fireflies r, snow r
# rain och rain_anim är samma regn, stilla resp. rinnande - bara en åt gången.
#
# Rörliga effekter använder `uniform float time`, och Hyprland laddar bara
# sådana shaders med debug:damage_tracking = 0 (hela skärmen ritas om 60
# ggr/s, mätt ~1,9 W extra). Med bara stillastående effekter står damage
# tracking kvar på 2 och det kostar i princip ingenting.
set -u

TEMPLATE="$HOME/.config/hypr/shaders/effects.glsl"
STATE="$HOME/.cache/hypr-effects"
OUT_DIR="$HOME/.cache"
ALL="grade evening groundfog grain frost rain rain_anim driftfog leaves fireflies snow"
ANIMATED="rain_anim driftfog leaves fireflies snow"

enabled() { [ -f "$STATE" ] && cat "$STATE" || true; }
has() { case " $(enabled) " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
save() { echo "$*" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' | sed 's/ $//' > "$STATE"; }
set_cfg() { hyprctl eval "hl.config({ $1 })" >/dev/null; }

sync() {
    local args=()
    for id in $ALL; do
        has "$id" && args+=("fx_$id=true") || args+=("fx_$id=false")
    done
    local animated=false any=false
    for id in $ANIMATED; do has "$id" && animated=true; done
    [ -n "$(enabled)" ] && any=true
    eww update "${args[@]}" fx_animated="$animated" fx_any="$any" 2>/dev/null || true
}

apply() {
    local ids animated=false defines="" id
    ids=$(enabled)
    # Gamla genererade shaders städas bort; nytt filnamn per innehåll så att
    # Hyprland garanterat laddar om (samma sökväg kan cachas).
    find "$OUT_DIR" -maxdepth 1 -name 'hypr-effects-*.glsl' -delete 2>/dev/null

    if [ -z "$ids" ]; then
        set_cfg 'decoration = { screen_shader = "" }'
        set_cfg 'debug = { damage_tracking = 2 }'
        sync
        return
    fi

    for id in $ids; do
        case " $ANIMATED " in *" $id "*) animated=true ;; esac
        # rain_anim = samma regn som rain, fast rörligt
        [ "$id" = "rain_anim" ] && id=rain
        defines+="#define FX_${id^^} 1"$'\n'
    done
    $animated && defines+="#define FX_TIME 1"$'\n'

    local tmp out
    tmp=$(mktemp "$OUT_DIR/hypr-effects-XXXXXX")
    { echo "#version 300 es"; printf '%s' "$defines"; cat "$TEMPLATE"; } > "$tmp"

    # Ladda aldrig en shader som inte kompilerar (skärmen kan bli svart)
    if command -v glslangValidator >/dev/null; then
        cp "$tmp" "$tmp.frag"
        if glslangValidator "$tmp.frag" | grep -q ERROR; then
            rm -f "$tmp" "$tmp.frag"
            notify-send "Skärmeffekter" "Shadern kompilerade inte - inget ändrat."
            return 1
        fi
        rm -f "$tmp.frag"
    fi
    out="$tmp-$(md5sum "$tmp" | cut -c1-8).glsl"
    mv "$tmp" "$out"

    if $animated; then
        # damage tracking av FÖRE en shader med time laddas (separata anrop,
        # en lua-tabell har ingen garanterad ordning)
        set_cfg 'debug = { damage_tracking = 0 }'
        set_cfg "decoration = { screen_shader = \"$out\" }"
    else
        set_cfg "decoration = { screen_shader = \"$out\" }"
        set_cfg 'debug = { damage_tracking = 2 }'
    fi
    sync
}

case "${1:-}" in
    toggle)
        id="${2:?id saknas}"
        case " $ALL " in *" $id "*) ;; *) echo "okänd effekt: $id" >&2; exit 1 ;; esac
        if has "$id"; then
            save $(enabled | tr ' ' '\n' | grep -vx "$id")
        else
            cur=$(enabled)
            # bara en regnvariant åt gången
            [ "$id" = "rain" ] && cur=$(echo "$cur" | tr ' ' '\n' | grep -vx rain_anim)
            [ "$id" = "rain_anim" ] && cur=$(echo "$cur" | tr ' ' '\n' | grep -vx rain)
            save $cur "$id"
        fi
        apply
        ;;
    off)   rm -f "$STATE"; apply ;;
    apply) apply ;;
    sync)  sync; date +%s ;;
    *)     sed -n '2,12p' "$0"; exit 1 ;;
esac
