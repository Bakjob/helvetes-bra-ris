# eww (ElKowars Wacky Widgets)

Widget-daemon, startas via `eww daemon` i [[hyprland|Hyprlands autostart]].

- `eww.yuck` — widget-definitioner (wifi-menu, volume-menu, battery-menu m.fl., som
  öppnas från [[waybar|waybar-moduler]] med `eww open <namn> --toggle`).
- `eww.scss` — styling.
- `scripts/` — hjälpskript för widgets.

## VPN-status

`scripts/vpn-status.sh` (defpoll `vpn_status`, 4 s) letar efter aktiva
NetworkManager-anslutningar av typen `vpn`, `wireguard` eller `tun` och visar
dem som en rad överst i wifi-menyn (guld låsikon när på). Jakob kör eduVPN, som
dyker upp som en NM-anslutning av typen `wireguard` med namnet "eduVPN".
`system-stats.sh` gör samma koll, så nät-raden i systemmenyn och waybar-tooltipen
visar "Ansluten · VPN". Bara status — ingen av/på-knapp (anslutning sköts i
eduVPN-klienten). En VPN som inte går via NetworkManager (t.ex. `wg-quick`
direkt) syns inte.

**`eww.scss` måste vara ren ASCII**, även i kommentarer. Annars faller hela
stilmallen bort tyst, se [[vault/03-felsokning/eww-locale-och-scss-quirks]].
