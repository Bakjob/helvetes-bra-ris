#!/bin/bash
# Volymstatus som JSON för eww.

export LC_ALL=C
vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
# Namnet på standardenheten - inte bara första enheten i listan (fel namn
# när t.ex. hörlurar är valda).
default_sink=$(pactl get-default-sink 2>/dev/null)
sink_desc=$(pactl list sinks 2>/dev/null | awk -v want="$default_sink" '
    /^\s*Name:/        { name = $2 }
    /^\s*Description:/ { if (name == want) { sub(/^\s*Description: /, ""); print; exit } }')

eww update selected_volume="${vol:-0}" 2>/dev/null
eww update selected_muted="$([ "$muted" = "yes" ] && echo true || echo false)" 2>/dev/null

python3 - "${vol:-0}" "${muted:-no}" "${sink_desc:-Ljudenhet}" <<'PYEOF'
import sys, json
vol, muted, sink = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({"volume": int(vol), "muted": muted == "yes", "sink": sink}))
PYEOF
