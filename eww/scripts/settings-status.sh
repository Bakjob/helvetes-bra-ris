#!/bin/bash
# Läge för alla reglage i inställningspanelen (settings-menu) som JSON.
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

python3 - "$bright" "$sunset_temp" "$idle" "$mic" "$dnd" "$shader" "$profile" "$bt_service" "$bt_on" <<'PYEOF'
import sys, json
bright, temp, idle, mic, dnd, shader, profile, bt_service, bt_on = sys.argv[1:10]
try:
    temp = int(temp)
except ValueError:
    temp = 6000
print(json.dumps({
    "brightness": int(bright) if bright.isdigit() else 50,
    # hyprsunset: 6000 K = neutral (identity), lägre = varmare nattljus
    "nightlight": temp < 6000,
    "keep_awake": idle != "true",
    "mic_muted": mic == "yes",
    "dnd": dnd.strip() == "true",
    "rain": shader.endswith("rain.glsl"),
    "profile": profile or "balanced",
    "bt_service": bt_service == "true",
    "bt_on": bt_on == "true",
}))
PYEOF
