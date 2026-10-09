#!/bin/bash
# Batteristatus + gissad tid kvar per power-profil, som JSON för eww.

export LC_ALL=C
BAT="/org/freedesktop/UPower/devices/battery_BAT1"
info=$(upower -i "$BAT" 2>/dev/null)
state=$(echo "$info" | awk '/state:/{print $2}')
pct=$(echo "$info" | awk '/percentage:/{print $2}')
energy=$(echo "$info" | awk '/^\s*energy:/{print $2}' | tr ',' '.')
rate=$(echo "$info" | awk '/energy-rate:/{print $2}' | tr ',' '.')
profile=$(powerprofilesctl get 2>/dev/null)

eww update selected_profile="$profile" 2>/dev/null

python3 - "$state" "$pct" "$energy" "$rate" "$profile" <<'PYEOF'
import sys, json

state, pct, energy, rate, profile = (sys.argv[1:6] + [""] * 5)[:5]

def fmt(h):
    try:
        h = float(h)
    except Exception:
        return "-"
    if h <= 0:
        return "-"
    hh = int(h)
    mm = int((h - hh) * 60)
    return f"{hh}h {mm}min"

mult = {"power-saver": 0.80, "balanced": 1.00, "performance": 1.30}
profile = profile if profile in mult else "balanced"

# upower ger engelska tillstand - visas pa svenska i menyn
states = {
    "charging": "laddar",
    "discharging": "laddar ur",
    "fully-charged": "fulladdat",
    "pending-charge": "väntar på laddning",
    "pending-discharge": "väntar",
    "empty": "tomt",
}

result = {
    "pct": pct or "?",
    "state": states.get(state, state or "okänt"),
    "rate": "?",
    "profile": profile,
    "t_saver": "-",
    "t_balanced": "-",
    "t_performance": "-",
}

try:
    rate_f = float(rate)
    result["rate"] = f"{rate_f:.1f}"
    if state == "discharging" and energy:
        energy_f = float(energy)
        baseline = rate_f / mult[profile]
        result["t_saver"] = fmt(energy_f / (baseline * mult["power-saver"]))
        result["t_balanced"] = fmt(energy_f / (baseline * mult["balanced"]))
        result["t_performance"] = fmt(energy_f / (baseline * mult["performance"]))
except Exception:
    pass

print(json.dumps(result))
PYEOF
