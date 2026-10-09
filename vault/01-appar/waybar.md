# waybar

Statusbar. Config: `waybar/config.jsonc` + `waybar/style.css`.

## Moduler (custom, vänster→höger ordning i bar)

- **`custom/dotfiles`** (⚙) — öppnar `~/dotfiles` i VS Code (`code --new-window ~/dotfiles`).
  Bytte namn från `custom/hyprland-config` och slutade peka på `rice.code-workspace`
  2026-09-14 — workspace-filen togs bort, onödigt lager när mappen kan öppnas direkt.
- **`custom/gpu`** — kör `scripts/gpu.sh`, klick öppnar `intel_gpu_top` i ett flytande
  kitty-fönster (`--class btop-float`).
- **`custom/cava`** — ljudvisualisering, kör `scripts/cava-waybar.sh` som i sin tur
  startar `cava -p ~/.config/cava/waybar.conf` (se [[cava]]).
- **`custom/power-profile`** — klick kör `scripts/power-profile-cycle.sh`.
- Batteri/wifi/volym-moduler öppnar eww-widgets (`eww open wifi-menu/volume-menu/battery-menu --toggle`).
- Flera moduler öppnar `btop` i ett flytande kitty-fönster (`--class btop-float`) för
  snabb systemvy.

## scripts/

`cava-waybar.sh`, `gpu.sh`, `power-profile.sh`, `power-profile-cycle.sh`.

## Relaterat

[[cava]], [[btop]], [[eww]]

## GPU-modulen

`custom/gpu` uppdateras var 15:e sekund och tar fyra prov över ~2 s
(`intel_gpu_top -n 4`). Fram till 2026-10-09 var det åtta prov (~4 s) var
8:e sekund, alltså mätning halva tiden.

## Wifi-knappen `custom/network` (2026-10-09)

`scripts/network.sh` visar signalstaplar och en sköld 󰦝 när VPN är på, och
tooltipen visar SSID, signal och VPN-namn. Klick öppnar eww-`wifi-menu`. Den
ligger före `pulseaudio`, vilket matchar `.align-wifi` (margin-right 256px) i
`eww.scss`. Förut gick wifi-listan bara att nå via "Nätverk"-raden i
systemmenyn, och Jakob hittade den inte.
