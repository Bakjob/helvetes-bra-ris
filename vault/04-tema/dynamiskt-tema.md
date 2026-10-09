# Dynamiskt tema per bakgrundsbild (wallust)

Beslutat 2026-09-15: "jag tror jag vill ha dymanisk tema per bakgrund... tema
baserat på färgerna i bilden. jag gillar dock det temat vi kommit fram till
här nu. så behåll den i någon av bakgrunderna." Alltså: varje bakgrundsbild
i loopen (se [[../02-beslut/changelog]]) får ett eget färgtema draget ur sina
egna färger, **utom** en vald ankarbild som alltid behåller den handgjorda
[[svensk-skog-palett|Svensk skog-paletten]] precis som den ser ut idag.

## Scope (bekräftat med AskUserQuestion)

- **Ankarbild:** `höstskog-1.jpg` (döpt om 2026-09-15, se
  [[../02-beslut/changelog]] — het ursprungligen `vårskog-1.jpg`, jag gissade
  fel årstid).
- **Vilka appar som får dynamiska färger just nu:** waybar, kitty, rofi,
  swaync, Hyprlands kantfärger, eww-menyerna (sedan 2026-10-09). **Inte**
  (ännu): wlogout, hyprlock, btop, fastfetch, starship, cava, wob. Hyprlock
  hålls medvetet statiskt, Jakob vill inte riskera att låsskärmen går sönder.
- **Intervall:** klockstyrt, varje heltimme (`OnCalendar=hourly`) — ändrat
  2026-09-15 från det ursprungliga 20-minutersvalet ("går det inte bara att
  koppla till klockan? så varje timme byts det") efter att systemet redan var
  aktiverat live.

## Arkitektur

```
wallust/
├── wallust.toml          symlinkad till ~/.config/wallust/wallust.toml
├── templates/             wallust-mallar (Tera/Jinja), en per app
│   ├── waybar-colors.css
│   ├── kitty-colors.conf
│   ├── swaync-colors.css
│   ├── hypr-colors.lua
│   └── rofi-colors.rasi
└── anchor/                statiska kopior av Svensk skog-paletten, en per app
    └── (samma 5 filnamn som ovan)

hypr/scripts/wallpaper-cycle.sh   orkestreringsskriptet, se nedan
systemd/user/wallpaper-cycle.{service,timer}   kör skriptet varje heltimme
```

`~/.config/wallust` är symlinkad till `wallust/` i det här repot (samma
mönster som resten av dotfiles) — wallust läser `wallust.toml` och
`templates/` därifrån helt automatiskt, ingen `-C`/`-d`-flagga behövs vid
körning.

De sex "colors"-filerna (`waybar/colors.css`, `kitty/colors.conf`,
`swaync/colors.css`, `hypr/colors.lua`, `rofi/colors.rasi`,
`eww/colors.scss`) är **inte
längre gitspårade** — de skrivs om av antingen wallust eller en `cp` från
`wallust/anchor/` varje bildbyte, så `wallust/anchor/*` är den faktiska
källan till sanning i git (`git rm --cached`, `.gitignore`).

## Orkestreringsskriptet (`hypr/scripts/wallpaper-cycle.sh`)

Körs som ett **systemd --user oneshot-jobb** (`wallpaper-cycle.service` +
`.timer`, `OnCalendar=hourly` — klockstyrt, se ovan) — medvetet **inte** en egen
`while true; do sleep 1200; done`-loop. Vi har redan städat upp tre separata
läckande bakgrundsprocess-buggar den här sessionen (cava, wob,
ac-sound-watch, se [[../03-felsokning/cava-process-lacka]]) orsakade av precis
den loop-stilen — en systemd-timer har ingen egen process mellan körningarna
och kan inte läcka på samma sätt.

Varje körning:
1. Läser en sorterad filnamnslista över `images/backgrounds/*.{jpg,png}`
   (samma ordning som hyprpapers gamla `order=default`).
2. Räknar upp ett index i `~/.cache/dotfiles-wallpaper-index` (roterar runt).
3. Pekar om symlinken `images/backgrounds/.current.jpg` mot den nya bilden.
4. **Om det är ankarbilden:** kopierar `wallust/anchor/*` rakt in i de sex
   colors-filerna. **Annars:** kör `wallust run <bild>`, som skriver samma
   sex filer via sina templates.
5. Byter faktisk bakgrund och plockar upp de nya färgerna:
   - `hyprpaper`: dödas och startas om (se nedan, varför). Startas via
     `hyprctl dispatch 'hl.dsp.exec_cmd("hyprpaper")'` så att den hamnar i
     Hyprland-sessionen och inte i tjänstens cgroup.
   - `hyprctl reload`: plockar upp `hypr/colors.lua` (`require("colors")` i
     `hyprland.lua`). Reloaden nollställer regn-shadern, så
     `toggle-rain.sh restore` slår på den igen om den var på.
   - `waybar`: **laddas om, startas inte om** (`SIGUSR2`, läser om config och
     CSS). `swaync`: `swaync-client --reload-css`. Fram till 2026-10-09
     dödades och startades båda om. Det stängde av Stör ej och tömde
     notishistoriken varje timme, och processerna hamnade i
     `wallpaper-cycle.service`s cgroup.
   - `eww`: läser om `colors.scss` själv när filen ändras.
   - `rofi`: **ingenting**, läser sina filer vid varje ny körning.
   - `kitty`: **ingenting automatiskt** — öppna fönster behåller sina färger
     tills de stängs (eller `ctrl+shift+f5` manuellt), nya fönster får de
     uppdaterade färgerna.

### Varför hyprpaper måste dödas/startas om för varje bildbyte

`hyprpaper` (0.8.4, hyprtoolkit-bygget) har **inget skriptbart sätt att byta
bild utifrån** — den gamla `hyprctl hyprpaper wallpaper ...`-textkommandot
finns inte längre, ersatt av ett binärt Hyprwire-objektprotokoll som inte är
menat att scriptas mot. Se [[../03-felsokning/hyprpaper-nytt-config-schema]].
Detta är också orsaken till att `hyprpaper.conf` numera pekar på en stabil
symlink (`.current.jpg`) istället för hela mappen med ett inbyggt
`timeout`/`order`-bildspel som förut — skriptet behöver **veta exakt vilken
bild som visas** för att kunna dra rätt wallust-tema ur den, vilket inte gick
att fråga hyprpapers interna bildspel om utifrån.

### `KillMode=process` i `wallpaper-cycle.service`

Skriptet startar hyprpaper/waybar/swaync som frikopplade processer
(`setsid ... & disown`) och avslutar sedan självt. systemds **standard**
`KillMode=control-group` skulle döda hela cgroupen — inklusive de precis
nystartade långlivade processerna — så fort skriptets huvudprocess är klar.
`KillMode=process` gör att bara skriptets egen process spåras, aldrig dess
frikopplade barn. Uteslöt ett alternativ (`systemd-run --user --scope` för
varje delprocess) eftersom det är beroende av att `WAYLAND_DISPLAY`/
`XDG_RUNTIME_DIR` redan importerats till den separata systemd
`--user`-managerns miljö, vilket inte är verifierat konfigurerat här — enkel
`setsid`/`disown` inom skriptets egen redan-korrekta miljö är robustare.

## Färgroller — mappning wallust → CSS/config-variabler

Alla fem mallar delar samma semantiska roller, valda för att fungera oavsett
bildens egna färger (inte bara for Svensk skog-liknande gröna bilder):

| Roll        | wallust-källa                          | Används till |
|---|---|---|
| `bg`        | `background`                           | Basbakgrund |
| `fg`        | `foreground`                           | Brödtext |
| `fg-dim`/`fg-muted` | `foreground \| darken(0.35)`   | Dämpad text |
| `accent`/`gold` | `color3 \| saturate(-0.5) \| darken(0.05)` | Primär highlight (motsvarar guld i Svensk skog) |
| `accent2`/`leaf` | `color4 \| saturate(-0.5) \| darken(0.05)` | Sekundär highlight |
| `red`       | `color1 \| saturate(-0.5)`              | Varning/fel |
| `green`     | `color2 \| saturate(-0.5) \| blend("8a9a5b")` | Success/laddar — blandas med [[svensk-skog-palett\|moss green-referensen]] 2026-09-19, se den filen för varför |
| `border`/`border-c` | `color8`                        | Kanter (alltid mörk/neutral ton) |
| `cyan`, `purple` (swaync/rofi) | `color6`/`color5 \| saturate(-0.5..-0.65) \| darken(...)` | Sekundära notis-/menyfärger |

### Varför `ansidark`/`lchansi`, inte `saliencedark`/`salience`

Testade `saliencedark` (wallusts default-liknande val) först — den sorterar
`color0`-`color15` efter hur **framträdande** en färg är i bilden, inte efter
klassisk ANSI-betydelse. Resultat på en testbild: `color1` ("röd" i våra
mallar) blev mörkblå, `color2` ("grön") blev grå. `ansidark` (med
`lchansi`-färgrymden) är byggd för att **bevara** ANSI:s slot-ordning
(svart/röd/grön/gul/blå/magenta/cyan/vit) oavsett bildinnehåll — vilket våra
mallar (`color1`=röd, `color2`=grön osv) förutsätter. Bytte, testade om,
korrekt röd/grön efter bytet.

### Varför `saturate(-0.5)` överallt på färgstarka roller

`ansidark` ger annars ganska mättade/neonaktiga primärfärger. Jakob har
tidigare uttryckt en tydlig preferens för dämpat/mulet över klart/soligt (se
[[design]], "mörkt/mulet/sinister vinner"). Testade wallusts globala
`saturation`-inställning (config-nyckel) först — **ingen märkbar effekt**
med `ansidark` (troligen för att paletten låser hue/mättnad ganska hårt redan
vid paletturvalet). Löste det istället per färgroll i mallarna med filtret
`saturate(-<negativt tal>)` (negativt värde minskar mättnaden i HSV-rymden,
se `wallust/src/colors.rs::saturate`) — fungerade direkt, testat och verifierat
med riktiga körningar mot `höst-utsikt-1.jpg`.

## Kvarstår / möjliga vidareutvecklingar

- **Mjuk övertoning vid bakgrundsbyte:** avfärdat 2026-09-15. Skulle kräva
  `awww` (aktivt underhållen efterträdare till det nedlagda `swww`,
  `awww-git` på AUR) istället för `hyprpaper`, eftersom hyprpaper helt saknar
  fade/transition-stöd (verifierat i källkoden, ingen sådan nyckel finns).
  Jakob valde att hoppa över det snarare än att bygga ännu ett Cargo/AUR-paket.
- Fler appar skulle kunna få dynamiska färger senare (wlogout, hyprlock,
  btop, fastfetch, starship, cava, wob) — medvetet utanför scope för
  den första omgången.
- Om fler bakgrundsbilder läggs till i `images/backgrounds/` uppdateras
  loopen automatiskt (skriptet läser mappen på nytt varje körning) — men
  kom ihåg att **inte döpa om/ta bort filer medan hyprpaper redan kör** utan
  att starta om den efteråt, se [[../03-felsokning/hyprpaper-nytt-config-schema]].
