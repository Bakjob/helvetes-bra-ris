# Väntar på Jakob

Saker jag inte kan eller inte ska göra själv — kräver sudo, ett beslut bara
Jakob kan ta, eller en handling utanför den här maskinens config (t.ex. testa
något live och bekräfta). Håll den här listan aktuell: ta bort raden när
punkten är klar, eller flytta den till [[../02-beslut/changelog]] med datum.

## Aktivt öppna

- **Titta på eww-menyerna** (2026-10-09). Färgerna kommer nu från det dynamiska
  temat, wifi-listan och volymmenyn (val av ljudenhet) är omgjorda, och det
  finns nya genvägar längst ner. Claude har inte sett resultatet (inga skärmdumpar av menyerna).
- **Starta Bluetooth om du vill använda det** (2026-10-09):
  `sudo systemctl enable --now bluetooth`. Tjänsten är avstängd, så
  Bluetooth-brickan i inställningspanelen visar "Bluetooth (av)" och gör inget.
- **Titta på inställningspanelen:** systemmenyn → Inställningar. Inte sedd av
  Claude.
- **Testa effektgalleriet** (2026-10-09): Inställningar → Effekter. Kolla att
  galleriet får plats på skärmen, att markdimman ligger *nere* (annars är
  y-axeln omvänd) och om det blir skarvar med stilla regn.
- **Titta på wlogout** (Super+Shift+E): text under ikonerna och guldkant vid
  hover. Inte sett av Claude.
- **Kolla efter nästa heltimme** att waybar och swaync fortfarande ser rätt ut,
  och att Stör ej ligger kvar om den var på. Det är första körningen där de
  laddas om i stället för att startas om.

## Löst (kvar som referens en kort tid)

- ~~Peka om git-remoten~~ — löst 2026-10-09. Repot flyttades till
  `Bakjob/helvetes-bra-ris`, och Jakob körde `git remote set-url`. Fetch och
  push fungerar mot den nya adressen.

- ~~Strömknapp-eko efter vila (försök 2, markörfil)~~ — **bekräftat
  fungerande 2026-09-18.** Jakob testade en riktig vila/väck-cykel:
  wlogout-menyn dök inte längre upp. Se
  [[../03-felsokning/strömknapp-ekar-efter-vila]] för hela historien
  (första försöket med en tidsstämpel hade en kapplöpning och fungerade
  inte i praktiken).

- ~~`satty`/`hyprsunset` inte installerade~~ — löst 2026-09-18, Jakob
  installerade båda (`sudo pacman -S satty hyprsunset`). `hyprsunset`
  startad live samma dag (låg direkt på kvällsprofilen, 4500K, eftersom
  klockan redan var efter 20:00). Skärmdumps-redigeringsflödet
  (`screenshot.sh` → notis → "Redigera" → `satty`) testat och bekräftat
  fungerande av Jakob.

- ~~`s2idle`-viloläget vaknar inte~~ — **verkar löst, bekräftat med ett
  kontrollerat test 2026-09-16.** Körde `systemctl suspend` medvetet;
  skärmen släcktes på riktigt och Jakob lyckades väcka den själv.
  Kärnloggen bekräftar en fullständig cykel: `PM: suspend entry (s2idle)`
  21:54:54 → `PM: suspend exit` 21:55:30 (36 sek). Hela riggen frisk
  efteråt (Hyprland/waybar/hyprpaper/hypridle, wifi återanslutet). **Enda
  reservationen:** det var ett kort, medvetet test — inte en lång
  vila/övernattning eller lock-stängning som de facto orsakade de
  ursprungliga låsningarna. Håll ett öga på det några dagar innan man
  litar på det helt. Se [[../03-felsokning/s2idle-vaknar-aldrig]].

- ~~Strömknappen syns inte/gör inget~~ — **löst och bekräftat 2026-09-16.**
  `linux-surface` exponerade en ny `gpio-keys`-enhet med `KEY_POWER` (se
  [[../03-felsokning/strömknapp-syns-inte]]), `systemd-logind` bevakar den
  nu, och Jakob bekräftade live: kort tryck fungerar. Hela kedjan
  (`hypr/keybinds.lua` → `XF86PowerOff` → wlogout, plus
  `logind.conf.d/power-button.conf` för kort/lång särskiljning) är nu
  verifierad i praktiken, inte bara i teorin.

- ~~wallust AUR-bygge (checksummefel)~~ — löst 2026-09-15,
  `updpkgsums && makepkg -si` i `~/.cache/yay/wallust`.
- ~~Dynamiskt wallust-tema inte aktiverat~~ — löst 2026-09-15, aktiverat live
  (`wallpaper-cycle.timer` kör nu, klockstyrt varje heltimme).
- ~~`linux-surface` inte installerad~~ — löst 2026-09-16, Jakob installerade
  själv. Kör `6.19.8-arch1-3-surface`, `surface_aggregator`+HID-moduler
  laddade, `acpi_osi="Windows 2022"` + `pci=hpiosize=0` i cmdline bekräftat.
  Se [[linux-surface-installation]] och [[../02-beslut/changelog]].
