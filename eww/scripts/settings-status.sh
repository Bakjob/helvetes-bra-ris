#!/bin/bash
# Läge för alla reglage i inställningspanelen (settings-menu), skrivs
# direkt till panelens eww-variabler (s_*).
# Varje kommando har timeout - bluetoothctl hänger t.ex. för evigt om
# bluetooth.service inte kör.

export LC_ALL=C
t() { timeout 2 "$@" 2>/dev/null; }

bright=$(t brightnessctl -m | cut -d, -f4 | tr -d '%')
sunset_temp=$(t hyprctl hyprsunset temperature)
idle=$(pgrep -x hypridle >/dev/null && echo true || echo false)
mic=$(t pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
dnd=$(t swaync-client -D)
shader=$(t hyprctl getoption decoration:screen_shader | awk 'NR==1 {print $2}')
profile=$(t powerprofilesctl get)

if systemctl is-active --quiet bluetooth; then
    bt_service=true
    bt_on=$(t bluetoothctl show | grep -q "Powered: yes" && echo true || echo false)
else
    bt_service=false
    bt_on=false
fi

# hyprsunset: 6000 K = neutral (identity), lägre = varmare nattljus
[ "${sunset_temp:-6000}" -lt 6000 ] 2>/dev/null && nightlight=true || nightlight=false
[ "$idle" = "true" ] && keep_awake=false || keep_awake=true
[ "$mic" = "yes" ] && mic_muted=true || mic_muted=false
[ "$(echo "$dnd" | tr -d '[:space:]')" = "true" ] && dnd=true || dnd=false
case "$shader" in *rain*.glsl) rain=true ;; *) rain=false ;; esac
case "$bright" in ''|*[!0-9]*) bright=50 ;; esac

# Håller panelens s_*-variabler i synk (se eww.yuck). Utskriften är bara en
# tidsstämpel - defpollen settings_tick finns för att skriptet ska köras.
eww update \
    s_brightness="$bright" s_nightlight="$nightlight" s_keep_awake="$keep_awake" \
    s_mic_muted="$mic_muted" s_dnd="$dnd" s_rain="$rain" \
    s_bt_service="$bt_service" s_bt_on="$bt_on" s_profile="${profile:-balanced}" 2>/dev/null
date +%s
