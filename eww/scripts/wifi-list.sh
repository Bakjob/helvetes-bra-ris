#!/bin/bash
# Lista över synliga Wi-Fi-nätverk som JSON-array för eww.
# Per nätverk: signalikon (staplar), skal-säkert SSID för onclick (ssid_q,
# ett ' i namnet förstörde annars kommandot) och om det är det anslutna nätet.

read -r -d '' PY <<'PYEOF'
import sys, json

def bars(signal):
    # Nerd Font-ikoner: 1-4 staplar
    if signal >= 75: return "󰤨"
    if signal >= 50: return "󰤥"
    if signal >= 25: return "󰤢"
    return "󰤟"

def split_nmcli(line):
    # nmcli -t escapar ':' och '\' i fält ('\:' resp '\\')
    parts, cur, esc = [], "", False
    for ch in line:
        if esc:
            cur += ch; esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append(cur); cur = ""
        else:
            cur += ch
    parts.append(cur)
    return parts

by_ssid = {}
for line in sys.stdin:
    parts = split_nmcli(line.rstrip("\n"))
    if len(parts) < 4:
        continue
    active, ssid, signal, security = parts[0], parts[1], parts[2], ":".join(parts[3:])
    if not ssid:
        continue
    sig = int(signal) if signal.isdigit() else 0
    entry = {
        "ssid": ssid,
        # för '...' i skal: ' -> '\''
        "ssid_q": ssid.replace("'", "'\\''"),
        "signal": sig,
        "icon": bars(sig),
        "secured": security.strip() not in ("", "--"),
        "active": active == "yes",
    }
    # Samma SSID kan sändas av flera accesspunkter - behåll den aktiva,
    # annars den med starkast signal.
    prev = by_ssid.get(ssid)
    if prev is None or entry["active"] or (not prev["active"] and entry["signal"] > prev["signal"]):
        by_ssid[ssid] = entry

nets = sorted(by_ssid.values(), key=lambda n: (not n["active"], -n["signal"]))
print(json.dumps(nets[:10], ensure_ascii=False))
PYEOF

LC_ALL=C nmcli -t -f active,ssid,signal,security dev wifi list 2>/dev/null | python3 -c "$PY"
