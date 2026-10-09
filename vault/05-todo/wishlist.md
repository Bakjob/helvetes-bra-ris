# Todo / wishlist

- [x] ~~eww "systemmeny"~~ — **byggd och live 2026-09-15.** Fristående 4:e meny
      (`system-menu` i `eww.yuck`), öppnas via en ny 📊-modul i waybar
      (`custom/systemstats`). Visar Minne/Temperatur/Nätverk + snabbåtgärder
      (Wifi på/av, Stör ej, Ljudinställningar → pavucontrol, Lås skärm).
      **CPU och GPU flyttades INTE in** — Jakob ville ha dem kvar synliga direkt
      i waybar (egna moduler, klick öppnar btop/intel_gpu_top som förut). Ingen
      utökad vy/grafer byggd (bedömdes som "hålla det enkelt", jfr swaync-
      beslutet). Datakälla: `eww/scripts/system-stats.sh` (delad med waybars
      tooltip via `waybar/scripts/systemstats-tooltip.sh`). De befintliga
      `wifi-menu`/`volume-menu`/`battery-menu` rördes inte, finns kvar separat.
- [x] ~~Testa en *riktig* `hyprctl reload`~~ — gjort via full omstart 2026-09-14,
      lua-configen verifierad fungerande i praktiken. Se
      [[../03-felsokning/hyprland-lua-migration]].
- [x] ~~Extrahera och dokumentera `rofi/colors.rasi`-paletten~~ — **överspelad
      och sedan klar ändå**: hela paletten gjordes om till "Svensk skog" (se
      [[../04-tema/svensk-skog-palett]]), `rofi/colors.rasi` är redan
      omskriven till den.
- [x] ~~Bestäm när `hypr.conf-backup-20260913/` kan arkiveras/tas bort~~ — borttagen
      2026-09-14, se changelog.
- [ ] Ta ställning till om `~/.gitconfig` ska in i dotfiles-repot.
- [ ] **Kärnfelsökningsprojekt: fixa touchscreen-buggen på riktigt, PR mot
      upstream.** Se [[../03-felsokning/touchscreen-slutade-fungera]] för
      full diagnos — felet sitter i mainline Linux (`drivers/hid/
      intel-thc-hid/intel-quickspi/quickspi-protocol.c`, funktionen
      `quickspi_handle_input_data`, "Wrong input report length"), inte i
      `linux-surface`s egen kod. Jakob tyckte det lät kul men ville inte
      börja direkt (2026-09-18) — kräver flera timmar iterativ felsökning
      (lägga till loggning, bygga om modulen, testa, upprepa) plus att
      skicka en riktig kärnpatch via mejl till en underhållarlista (inte
      en vanlig GitHub-PR, eftersom det är mainline-kärnan) om en fix
      hittas. Börja med: lägg till loggning av både deklarerad
      (`input_len`) och faktisk (`buf_len`) buffertstorlek i
      `quickspi_handle_input_data`, bygg om modulen, reproducera felet,
      läs loggen.
- [x] ~~Skapa GitHub-repo och pusha~~ — `HexagogoGames/helvetes-bra-ris`, klart
      2026-09-14.
- [x] ~~Spotify + Spicetify~~ — **klart och live 2026-09-15.** Jakob
      installerade `spotify-launcher` (finns i officiella `extra`-repot,
      ingen AUR behövdes för Spotify självt) + `yay -S spicetify-cli`.
      Claude laddade ner/startade klienten (`spotify-launcher --no-exec`
      för att inte tvinga fram GUI-fönstret i onödan, sen en riktig start
      för att skapa prefs-filen), Jakob loggade in själv. Byggde ett eget
      tema `~/.config/spicetify/Themes/SvenskSkog/` (`color.ini` mot
      [[../04-tema/svensk-skog-palett]], `user.css` baserad på
      spicetifys egen `SpicetifyDefault`-mall) — verifierat mot den
      riktiga referensmallen i `/opt/spicetify-cli/Themes/SpicetifyDefault/`
      istället för att gissa color.ini-formatet. `spicetify backup apply`
      kört, bekräftat live med skärmdump (mörkgrön bakgrund, guld
      progressbar). **Flyttad in i dotfiles-repot** (`spicetify/Themes/
      SvenskSkog/`, symlinkad tillbaka till `~/.config/spicetify/Themes/
      SvenskSkog`) — bara själva temat, inte `CustomApps`/`Extensions`/
      `config-xpui.ini` (maskinspecifikt/nedladdad tredjepartskod, inte
      värt att versionera).

## Genomgång 2026-10-09 (Opus) — inte åtgärdat än

Hittat vid en genomgång av hela repot. Jakob valde vilka punkter som skulle göras, se changelog 2026-10-09.

- [x] (klart 2026-10-09) `wallpaper-cycle.sh` startar om swaync varje timme. Då stängs Stör ej av och
      notishistoriken försvinner. waybar/swaync/hyprpaper hamnar dessutom i
      tjänstens cgroup. Förslag: ladda om waybar med `SIGUSR2` och swaync med
      `swaync-client -rs`, och starta hyprpaper via `hyprctl dispatch exec`.
- [x] (klart 2026-10-09) Varje timme körs `hyprctl reload`, som stänger av regn-shadern. Markörfilen
      står kvar, så nästa Super+Shift+W gör ingenting synligt.
- [x] (klart 2026-10-09) Gamla gröna (före mossgrönt) finns kvar i `eww.scss`, `hyprlock.conf`,
      `wlogout/style.css` och `wallust/anchor/swaync-colors.css`.
- [x] (klart 2026-10-09) Rubriken i eww-volymmenyn visar första ljudenhetens namn, inte standardenheten.
- [x] (klart 2026-10-09) Wifi-lösenordet skickas via en skal-sträng. Ett `'` i lösenordet förstör
      kommandot, och lösenordet syns i processlistan.
- [ ] Rofi-regeln (`class Rofi`, opacitet) gäller troligen inte. Rofi 2.0 körs
      som layer på Wayland.
- [x] (eww klart 2026-10-09) eww, hyprlock och wlogout följer inte det dynamiska temat (hårdkodade färger). Hyprlock lämnas medvetet statisk, wlogout är kvar.
- [x] (klart 2026-10-09) Inaktuella kommentarer och dokument: "var 20:e minut" (timern kör varje
      heltimme), satty-kommentaren i keybinds, hyprlang2lua-TODO-rubriker,
      swaybg i `00-oversikt/system.md`, trasig länk `suspend-s2idle-uppstartsfel`,
      README saknar spicetify/wallust/systemd.
- [ ] Stör ej-brickan i eww synkas aldrig mot swayncs faktiska läge.
- [x] (klart 2026-10-09) `gpu.sh` kör `intel_gpu_top` i 4 s av varje 8 s-intervall.
