hl.on("hyprland.start", function()
    -- Wallpaper (bytt från swaybg 2026-09-14): hyprpaper, egen config i hyprpaper.conf
    hl.exec_cmd("hyprpaper")
    -- Cursor-tema (beslutat i temaomdesignen): Adwaita, 24px
    hl.exec_cmd("hyprctl setcursor Adwaita 24")
    hl.exec_cmd("hypridle")
    -- Blåljusfilter, egen config i hyprsunset.conf (profiler för dag/kväll)
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("~/.config/hypr/scripts/ac-sound-watch.sh")
    hl.exec_cmd("~/.config/hypr/scripts/wob-init.sh")
    hl.exec_cmd("eww daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("sh -c 'SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket ssh-add ~/.ssh/id_ed25519'")
end)

