#!/bin/bash
# Wifi + VPN för waybar: signalstaplar (och sköld om VPN är på) som text,
# SSID/signal/VPN i tooltip. Klick öppnar eww-wifi-menyn (se config.jsonc).

export LC_ALL=C
radio=$(nmcli radio wifi 2>/dev/null)
line=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -1)
vpn=$(~/.config/eww/scripts/vpn-status.sh)

python3 - "$radio" "$line" "$vpn" <<'PYEOF'
import sys, json
radio, line, vpn = sys.argv[1], sys.argv[2], json.loads(sys.argv[3] or "{}")

ssid, signal = "", 0
if line:
    parts = line.split(":")
    ssid, signal = ":".join(parts[1:-1]), int(parts[-1] or 0)

if radio != "enabled":
    icon, tip, cls = "󰤭", "Wi-Fi av", "off"
elif not ssid:
    icon, tip, cls = "󰤮", "Inte ansluten", "disconnected"
else:
    icon = "󰤨" if signal >= 75 else "󰤥" if signal >= 50 else "󰤢" if signal >= 25 else "󰤟"
    tip, cls = f"{ssid} · signal {signal}%", "connected"

text = icon
if vpn.get("active"):
    text += " 󰦝"
    tip += f"\nVPN: {vpn.get('name', '')}"
    cls += " vpn"

tip += "\n\nKlicka för nätverk"
print(json.dumps({"text": text, "tooltip": tip, "class": cls.split()}, ensure_ascii=False))
PYEOF
