#!/bin/bash
# Ansluter med lösenordet användaren skrivit i eww-dialogen.
#
# SSID och lösenord hämtas från eww-variablerna (wifi_connect_ssid/_pw)
# istället för att klistras in i onclick-strängen - ett ' i lösenordet
# förstörde annars skal-kommandot. (Lösenordet syns fortfarande kort i
# processlistan medan nmcli ansluter - `device wifi connect` har inget
# passwd-file-alternativ, bara `connection up` har det.)

SSID=$(eww get wifi_connect_ssid)
PASSWORD=$(eww get wifi_connect_pw)

if [ -z "$PASSWORD" ] || [ -z "$SSID" ]; then
    exit 0
fi

eww update wifi_connect_status="connecting"

if nmcli device wifi connect "$SSID" password "$PASSWORD" 2>/tmp/wifi-connect-err.log; then
    eww update wifi_connect_pw="" wifi_connect_status="success"
    sleep 1.5
    eww update wifi_connect_status="connecting"
    eww close wifi-connect 2>/dev/null
else
    msg=$(tail -1 /tmp/wifi-connect-err.log)
    eww update wifi_connect_pw="" wifi_connect_error_msg="$msg" wifi_connect_status="error"
fi
