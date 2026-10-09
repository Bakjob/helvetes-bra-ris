# System

- **Distro:** EndeavourOS (Arch-baserad)
- **Session:** Wayland, startas via GDM (`gdm-wayland-session` → `start-hyprland`)
- **WM:** [[../01-appar/hyprland|Hyprland]] 0.56.2
- **Terminal:** [[../01-appar/kitty|kitty]]
- **Shell:** bash ([[../01-appar/bash|.bashrc]]) med [[../01-appar/starship|starship]]-prompt
- **Statusbar:** [[../01-appar/waybar|waybar]]
- **Widgets:** [[../01-appar/eww|eww]] (daemon, wifi/volym/batteri-menyer)
- **App-launcher:** [[../01-appar/rofi|rofi]]
- **Notiser:** [[../01-appar/swaync|swaync]]
- **Power-meny:** [[../01-appar/wlogout|wlogout]]
- **Volym/ljusstyrka-OSD:** [[../01-appar/wob|wob]]
- **Ljudvisualisering:** [[../01-appar/cava|cava]] (inbäddad i waybar)
- **Systemmonitor:** [[../01-appar/btop|btop]]
- **Fetch-verktyg:** [[../01-appar/fastfetch|fastfetch]]
- **Wallpaper:** `hyprpaper`, byts varje heltimme av `wallpaper-cycle` (bilder i `images/backgrounds/`, tema via wallust, se [[../04-tema/dynamiskt-tema]])
- **Skärmlås:** `hyprlock` + `hypridle`

## Var config faktiskt ligger

Sedan 2026-09-14 ligger all rice-config i `~/dotfiles/` (git-repo), symlinkad in i
`~/.config/*`. Se [[dotfiles-struktur]] för detaljer och [[../02-beslut/changelog]]
för själva migreringen.

## XDG

`$XDG_CONFIG_HOME` är inte satt → alla program faller tillbaka på default `~/.config`.
