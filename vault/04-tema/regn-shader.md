# Regn-shader — experimentell, opt-in

Jakob ville förstärka "blöt höstskog"-känslan (se [[svensk-skog-palett]],
[[design]]) med en visuell regneffekt: "lite misty kanske och dunkelt, och
väldigt väldigt blött". Bad uttryckligen om att det **inte ska vara
hårdkodat i systemet** eftersom han inte är säker på om han gillar det —
bryr sig mycket om både prestanda och utseende, och vill kunna strunta i
det helt om det inte funkar.

## Research innan implementation (2026-09-18)

Ingen färdig regn-shader för Hyprland hittades — sökte igenom de två stora
community-shadersamlingarna (`sijan-dev/HyprShades`, `0x15BA88FF/
hyprshaders`, inga har regn) och en bred GitHub-kodsökning. Bekräftade
istället direkt i Hyprlands egen källkod (`src/render/OpenGL.cpp`,
`applyScreenShader`/`SHADER_TIME`) att `decoration:screen_shader` stödjer
en valfri `uniform float time` som Hyprland förser med en löpande klocka
— animerade effekter (droppar som rör sig) är alltså tekniskt möjliga,
inte bara statiska färgfilter. Gränssnittet (`sampler2D tex`,
`in vec2 v_texcoord`, `#version 300 es`) bekräftades mot en riktig,
fungerande community-shader (`blue-light-filter.glsl`) istället för att
gissas.

## Arkitektur — medvetet inte hårdkodad

- `hypr/shaders/rain.glsl` — själva shadern. Ligger inert i repot, gör
  ingenting förrän den aktiveras.
- `hypr/scripts/toggle-rain.sh` — slår på/av **live** via
  `hyprctl eval 'hl.config({ decoration = { screen_shader = ... } })'`, rör
  ingen configfil. `hyprctl keyword` fungerar inte med lua-config ("keyword
  can't work with non-legacy parsers"), så den gamla versionen gjorde aldrig
  något efter lua-migreringen (upptäckt 2026-10-09). Av/på läses från
  `hyprctl getoption`. Shadern använder `uniform float time`, och Hyprland vägrar
  ladda den så länge `debug:damage_tracking` inte är 0 ("screen shader uses
  uniform time which requires debug damage tracking to be switched off").
  Skriptet stänger därför av damage tracking före shadern och slår på den igen
  (2) när regnet stängs av. När regnet är på ritas hela skärmen om varje
  bildruta, vilket kostar lite batteri. Markörfilen `~/.cache/rain-shader-on` betyder "ska vara
  på", och `wallpaper-cycle.sh` kör `toggle-rain.sh restore` efter sin
  timvisa `hyprctl reload`.
- `hypr/keybinds.lua`: `Super+Shift+W` (ledig, `R` var redan upptagen av
  waybar-omstarten) kör toggle-skriptet.
- **Ingen autostart** — av som standard varje inloggning, helt opt-in per
  session. Gillar Jakob inte den räcker det att ta bort keybind-raden i
  `keybinds.lua`; `rain.glsl`/`toggle-rain.sh` kan lämnas kvar orörda
  eftersom de aldrig körs av sig själva.

## Effekten (allt justerbart via namngivna konstanter högst upp i filen)

- Två lager procedurella "droppar" (billig hash-baserad rutnätsteknik,
  ingen texturuppslagning utöver själva skärmbilden) — stora långsamma
  droppar + smala snabbare rinnande streck, båda med en radiell
  lins-förvrängning som ser ut som vatten som böjer ljuset.
- Lågfrekvent, sakta drivande dis (`MIST_AMOUNT`/`MIST_COLOR`).
- Mörkläggning + svag vinjett för den dunkla känslan (`DARKEN`/
  `VIGNETTE_STRENGTH`).
- Prestandaval: exakt en texturuppslagning av skärminnehållet totalt
  (distortionen räknas ut i förväg, sedan en enda `texture(tex, ...)`),
  och droppelagren gör en tidig `return` för de allra flesta pixlar som
  inte ligger nära en droppe — båda medvetna avvägningar för Jakobs
  uttalade prestandaoro.

## Status

Byggd 2026-09-18, inte utvärderad live än av Jakob. Om känslan/prestandan
inte känns rätt: justera konstanterna direkt i `rain.glsl` (ingen
programmeringskunskap krävs, bara siffror), eller strunta i hela grejen —
den är designad för att vara helt riskfri att bara låta ligga oanvänd.

## Version 2 (2026-10-09)

Jakob tyckte att den första versionen hade kantiga moln och för otydliga droppar.
- **Disen** var `hash(floor(uv * 3))`, alltså hårda 3×3-rutor. Nu används två
  lager mjukt value noise som driver åt olika håll.
- **Dropparna** fungerar som små linser: de visar bilden spegelvänd
  (`-d * REFRACTION`) och har ljus glans och mörk kant. Två lager stillastående
  droppar dyker upp och avdunstar, och större droppar rinner ner med lite
  sidledsvickning. De lämnar ett spår av småpärlor och en klarare strimma i disen.
- Fortfarande bara aritmetik och en texturuppslagning per pixel. Alla
  reglage är konstanter överst i filen.
- Kompilerar med `glslangValidator`. En Python/numpy-version användes för att
  förhandsgranska en bildruta mot bakgrundsbilden innan Jakob testade.

**Energi:** med regnet på drog datorn ~11,1 W (upower energy-rate, normal
användning). Det mesta av merkostnaden kommer från att damage tracking är av, så
hela skärmen och blurren komponeras om 60 gånger per sekund. Shaderns matte är en
liten del.

## Stillastående som standard (2026-10-09)

Mätt med upower och `gpu.sh` vid normal användning:

| | Effekt | GPU |
|---|---|---|
| Regn av | ~9,25 W | ~9 % |
| Animerat regn | ~11,1 W | ~29 % |

Kostnaden kommer från animationen (damage tracking av, hela skärmen och blurren
ritas om 60 ggr/s), inte från shaderns matte. En enklare shader hade inte hjälpt
nämnvärt. Därför:
- **Super+Shift+W** (och Regn-brickan i inställningspanelen): *stillastående*
  regn. `toggle-rain.sh` genererar `~/.cache/hypr-rain-static.glsl` från
  `rain.glsl` med `time` som konstant. Utan `uniform float time` kan damage
  tracking vara kvar, så det är i princip gratis.
- **Super+Alt+W**: animerat regn som förut.
- Markörfilen `~/.cache/rain-shader-on` innehåller läget, så `restore` slår på
  rätt variant efter den timvisa reloaden.

Osäkert: om en stillastående screen shader som läser grannpixlar (linsbrytningen)
ger skarvar runt delar av skärmen som ritas om. Håll utkik efter det.
