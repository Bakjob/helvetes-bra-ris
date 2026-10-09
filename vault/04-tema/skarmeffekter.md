# Skärmeffekter (screen shader)

Byggt 2026-10-09 på Jakobs begäran: "bygg alla dessa. som inställning i
inställningar. gärna med preview fönster på ett snyggt sätt." Ersätter den
fristående regn-shadern (se [[regn-shader]] för historiken).

## Arkitektur

- `hypr/shaders/effects.glsl` är en **mall** med alla effekter, var och en inom
  `#ifdef FX_<NAMN>`.
- `hypr/scripts/effects.sh` sätter ihop den riktiga shadern: `#version 300 es`
  plus en `#define` per vald effekt, skriver den till
  `~/.cache/hypr-effects-<hash>.glsl` och laddar den live med
  `hyprctl eval 'hl.config({ decoration = { screen_shader = ... } })'`.
  - Nytt filnamn per innehåll, så att Hyprland garanterat laddar om.
  - Kompileras med `glslangValidator` först. Vid fel laddas inget och en notis
    visas, eftersom en trasig skärm-shader kan göra skärmen svart.
  - Valda effekter sparas i `~/.cache/hypr-effects`. `wallpaper-cycle.sh` kör
    `effects.sh apply` efter sin timvisa `hyprctl reload`.
- Hyprland kan bara ha **en** skärm-shader åt gången. Därför en mall i stället
  för en fil per effekt, så att alla effekter kan kombineras.

## Kostnad: stillastående vs rörligt

Effekter som använder `uniform float time` kräver `debug:damage_tracking = 0`
(hela skärmen ritas om 60 ggr/s). Mätt med rörligt regn: **~1,9 W extra**
(9,25 → 11,1 W, GPU 9 → 29 %). `effects.sh` stänger av damage tracking bara när
minst en rörlig effekt är vald (`#define FX_TIME`). Annars blir `time` en
konstant, damage tracking står kvar på 2 och det kostar i princip ingenting.

| id | Namn | Typ |
|---|---|---|
| `grade` | Höstljus: varma skuggor, mossgröna mellantoner, vinjett | stillastående |
| `evening` | Kvällsläge: mörkare, kallare | stillastående |
| `groundfog` | Markdimma längs nederkanten | stillastående |
| `grain` | Filmkorn (ett korn per pixel) | stillastående |
| `frost` | Frost som växer in från hörnen | stillastående |
| `rain` | Regn, stilla droppar och dis | stillastående |
| `rain_anim` | Regn, rinnande (samma kod, med tid) | rörlig |
| `driftfog` | Drivande dimma | rörlig |
| `leaves` | Fallande höstlöv | rörlig |
| `fireflies` | Eldflugor, mest nere vid "marken" | rörlig |
| `snow` | Snö i tre djup | rörlig |

`rain` och `rain_anim` utesluter varandra.

## Galleriet (eww `effects-menu`)

Öppnas från Inställningar → brickan "Effekter". Varje kort har förhandsbild,
namn, kostnad (Gratis eller ~2 W) och beskrivning. Klick slår på/av, och kortet
"Inga effekter" stänger av allt. Längst ner står det om något rörligt är på.
Snabbtangenter: Super+Shift+W = regn, Super+Alt+W = rinnande regn.

## Förhandsbilderna

`hypr/scripts/render-effect-previews.py` är en numpy-kopia av shaderns matte
som renderar varje effekt mot `höstskog-1.jpg` i full upplösning. Den beskär per
effekt (frost i hörnet, korn i 1:1) och sparar 360×240 PNG med rundade hörn i
`images/effect-previews/` (GTK klipper inte bilder efter border-radius).
**Håll den i synk med `effects.glsl`** och kör om den när konstanter ändras.
Förhandsbilderna användes också för att finjustera effekterna innan Jakob såg
dem. Första versionen hade för svag dimma, för få och för små löv, och frost som
såg ut som glödande maskar.

## Osäkert / att hålla koll på

- Koordinaterna antar att `v_texcoord.y = 0` är **överst** (markdimman nere,
  löven faller nedåt). Det är inte verifierat på riktigt, men det
  rörliga regnet har sett rätt ut i den riktningen.
- Stillastående effekter som läser grannpixlar (regnets linsbrytning) med
  damage tracking på kan ge skarvar där skärmen ritas om delvis.
- `ASPECT`/`SCREEN` är hårdkodade för 2256×1504.
