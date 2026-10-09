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

## Färger följer det dynamiska temat (2026-10-09)

`eww.scss` har inga hårdkodade färger längre. Den importerar `colors.scss`
(`$bg`, `$fg`, `$fg-dim`, `$accent`, `$green`, `$red`, `$border`, `$hover`),
som `wallpaper-cycle.sh` skriver vid varje bakgrundsbyte: med wallust från
`wallust/templates/eww-colors.scss`, eller som kopia av
`wallust/anchor/eww-colors.scss` för ankarbilden. `colors.scss` är gitignorerad.
Mallen måste också vara ren ASCII (se ovan).

## Menyerna stängs när man väljer något

Knappar som öppnar ett program eller gör något stort (ljudinställningar,
inställningar, lås, vila, starta om, stäng av) kör `eww close <meny>;` först.
Tidigare låg menyn kvar ovanpå programmet som öppnades. Volym-, wifi- och
batterimenyn har också fått en genväg längst ner: Ljudinställningar
(pavucontrol), Nätverksinställningar (`gnome-control-center wifi`) och
Energiinställningar (`gnome-control-center power`).

## Wifi-lösenord

`wifi-submit-password.sh` läser SSID och lösenord med `eww get`
(`wifi_connect_ssid`/`wifi_connect_pw`) i stället för att få dem inklistrade i
onclick-strängen. Förut förstörde ett `'` i lösenordet kommandot. Lösenordet
syns fortfarande kort i processlistan medan nmcli ansluter, eftersom
`nmcli device wifi connect` saknar passwd-file.

## Volymmenyn: val av ljudenhet (2026-10-09)

`scripts/audio-sinks.sh` (defpoll `audio_sinks`) listar alla utgångar med
`pactl -f json list sinks`. Standardenheten ligger överst med bock. Klick kör
`pactl set-default-sink`, och PipeWire flyttar då med pågående ljud.

## Wifi-listan (2026-10-09)

Signalen visas som staplar (Nerd Font 󰤟/󰤢/󰤥/󰤨) och procenten finns i tooltipen.
Det anslutna nätet ligger överst med bock och texten "Ansluten", och ett klick på
det gör ingenting (förut startade det om anslutningen). `wifi-list.sh` ger
också `ssid_q`, ett skal-escapat SSID för onclick, så ett `'` i nätverksnamnet
inte förstör kommandot.

## Svenska

All text i menyerna är på svenska. Batteriprofilerna heter Strömsparläge,
Balanserat och Prestanda, och `battery.sh` översätter upowers tillstånd
(discharging → "laddar ur" osv).

## gnome-control-center utanför GNOME

`gnome-control-center` vägrar starta under Hyprland ("only supported under GNOME
and Unity"). Alla genvägar kör den därför med `XDG_CURRENT_DESKTOP=GNOME`.
Panelerna för wifi, Bluetooth, ljud, energi, skrivare och användare fungerar.
Skärm-, tangentbords- och muspanelerna påverkar inte Hyprland.

## Inställningspanelen `settings-menu` (2026-10-09)

Öppnas från "Inställningar" i systemmenyn. Läget kommer från
`scripts/settings-status.sh` (defpoll `settings`, 3 s, alla kommandon har
timeout) och klicken går till `scripts/settings-toggle.sh <åtgärd>`, som
uppdaterar `settings` direkt efteråt.
- Ljusstyrka: reglage, minst 5 % så att skärmen aldrig blir helt svart.
- Brickor: Nattljus (hyprsunset-IPC, 4500 K ↔ neutral; schemat tar över vid
  nästa profilbyte), Håll vaken (stoppar/startar hypridle), Mikrofon av, Stör ej,
  Bluetooth och Regn.
- Energiprofil: Spara / Balans / Prestanda.
- Byt bakgrund nu (startar `wallpaper-cycle.service`), och Fler inställningar
  (gnome-control-center).

Bluetooth kräver att `bluetooth.service` kör. Den var avstängd 2026-10-09, och
`bluetoothctl` hänger då i stället för att ge fel, därav alla timeouts.

### Responsivitet (2026-10-09)

Första versionen av panelen kändes som att klick ibland inte gick fram. Brickorna
bytte läge först när skriptet och en ny statusläsning var klara (upp till ett par
sekunder), och ljusstyrkereglaget fick tillbaka värden mitt i en dragning. Nu
används samma optimistiska mönster som i resten av eww: `s_*`-variabler som
sätts direkt i onclick, åtgärden körs i bakgrunden (`&`), och
`settings-status.sh` synkar variablerna varje tick. Ljusstyrkan sätts direkt med
`brightnessctl` i onchange.
