#!/bin/bash
# Öppnar anslut-dialogen och försöker direkt (funkar utan lösenord om
# nätverket redan är sparat sen tidigare).

SSID="$1"

eww close wifi-menu 2>/dev/null
eww update wifi_connect_ssid="$SSID" wifi_connect_pw="" wifi_connect_error_msg="" wifi_connect_status="connecting"
eww open wifi-connect --arg ssid="$SSID"

if nmcli connection up id "$SSID" 2>/tmp/wifi-connect-err.log; then
    eww update wifi_connect_status="success"
    sleep 1.5
    eww update wifi_connect_status="connecting"
    eww close wifi-connect 2>/dev/null
else
    eww update wifi_connect_status="need_password"
fi
