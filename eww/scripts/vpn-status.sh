#!/bin/bash
# Aktiv VPN-anslutning (via NetworkManager) som JSON för eww.
# Räknar typerna vpn (openvpn m.fl. plugins), wireguard och tun - eduVPN
# skapar t.ex. en NM-anslutning av typen wireguard med enheten "eduVPN".

LC_ALL=C nmcli -t -f NAME,TYPE con show --active 2>/dev/null | python3 -c "
import sys, json
names = []
for line in sys.stdin:
    name, _, typ = line.rstrip('\n').rpartition(':')
    if typ in ('vpn', 'wireguard', 'tun'):
        names.append(name.replace('\\\\:', ':'))
print(json.dumps({'active': bool(names), 'name': ', '.join(names)}))
"
