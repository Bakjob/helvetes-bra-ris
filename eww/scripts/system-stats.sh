#!/bin/bash
# Snapshot av minne/temp/nätverk för eww system-menu (defpoll, se eww.yuck).
# CPU/GPU visas direkt i waybar istället (Jakobs val 2026-09-15) - inte med här.
# LC_ALL=C tvingat: systemet kör svensk locale där free byter fältnamn
# ("Mem:" -> "Minne:") - se vault/03-felsokning/eww-locale-parsing.md.

mem=$(LC_ALL=C free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
temp=$(($(cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null || echo 0) / 1000))

if LC_ALL=C nmcli -t -f STATE g 2>/dev/null | grep -q "^connected"; then
    net_state="Ansluten"
    # Visa VPN direkt i nät-raden (och därmed i waybar-tooltipen)
    if LC_ALL=C nmcli -t -f TYPE con show --active 2>/dev/null | grep -qxE "vpn|wireguard|tun"; then
        net_state="Ansluten · VPN"
    fi
else
    net_state="Frånkopplad"
fi

printf '{"mem": "%s", "temp": "%s", "net": "%s"}\n' "${mem:-0}" "${temp:-0}" "$net_state"
