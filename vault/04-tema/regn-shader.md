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
  `hyprctl getoption`. Markörfilen `~/.cache/rain-shader-on` betyder "ska vara
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
