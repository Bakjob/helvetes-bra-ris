#!/bin/bash
# Åtgärder för inställningspanelen (settings-menu i eww.yuck). Uppdaterar
# panelens läge direkt efteråt så att reglaget inte väntar på nästa poll.

refresh() {
    eww update settings="$(~/.config/eww/scripts/settings-status.sh)" 2>/dev/null
}

case "$1" in
    nightlight)
        # hyprsunset-IPC. Schemat i hypr/hyprsunset.conf tar över igen vid
        # nästa profilbyte (07:30 / 20:00).
        temp=$(timeout 2 hyprctl hyprsunset temperature 2>/dev/null)
        if [ "${temp:-6000}" -lt 6000 ] 2>/dev/null; then
            hyprctl hyprsunset identity >/dev/null
        else
            hyprctl hyprsunset temperature 4500 >/dev/null
        fi
        ;;
    keep-awake)
        # "Håll vaken" = hypridle stoppad (ingen dimning/låsning/vila)
        if pgrep -x hypridle >/dev/null; then
            pkill -x hypridle
        else
            hyprctl dispatch 'hl.dsp.exec_cmd("hypridle")' >/dev/null
        fi
        ;;
    mic)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        ;;
    dnd)
        swaync-client -d >/dev/null
        ;;
    rain)
        ~/.config/hypr/scripts/toggle-rain.sh
        ;;
    bluetooth)
        if ! systemctl is-active --quiet bluetooth; then
            notify-send "Bluetooth är inte igång" "Tjänsten bluetooth.service körs inte. Starta den med: sudo systemctl enable --now bluetooth"
        elif timeout 2 bluetoothctl show | grep -q "Powered: yes"; then
            timeout 3 bluetoothctl power off >/dev/null
        else
            timeout 3 bluetoothctl power on >/dev/null
        fi
        ;;
    wallpaper)
        systemctl --user start --no-block wallpaper-cycle.service
        ;;
    brightness)
        brightnessctl set "$2%" >/dev/null
        ;;
    profile)
        powerprofilesctl set "$2"
        eww update selected_profile="$2"
        ;;
esac

sleep 0.2
refresh
