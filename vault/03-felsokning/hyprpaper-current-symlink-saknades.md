# Bugg 2026-09-15: bakgrund borta efter omstart — `.current.jpg` fanns inte än

## Vad hände

Efter en (ofrivillig, se [[s2idle-vaknar-aldrig]]) hård omstart kom
Jakob tillbaka till en svart/tom bakgrund.

## Orsak

Egen miss i utrullningen av [[../04-tema/dynamiskt-tema]]: `hyprpaper.conf`
ändrades till att peka på en stabil symlink,
`images/backgrounds/.current.jpg`, som `hypr/scripts/wallpaper-cycle.sh`
skapar första gången den körs. Men skriptet hade bara committats — det hade
**aldrig körts en enda gång ännu** (väntade på Jakobs OK att aktivera
systemet live). Symlinken fanns alltså inte, `hyprpaper` startade om vid
omstarten med en `path` som pekade på ingenting, och renderade sin
hårdkodade svarta bakgrundsrektangel (samma mekanism som
[[hyprpaper-nytt-config-schema]], bugg 2026-09-15 tidigare samma dag, men en
annan bakomliggande orsak).

## Fix

Skapade symlinken manuellt mot ankarbilden (`höstskog-1.jpg`) och startade om
hyprpaper. Inget wallust-tema kördes, inget annat startades om — ren
återställning, inget av det dynamiska temasystemet aktiverades i samband med
detta.

## Lärdom / kvarstående skörhet

Om `.current.jpg` någonsin försvinner (färsk klon av repot på en ny maskin,
`git clean`, manuell radering) och hyprpaper startar om innan
`wallpaper-cycle.sh` hunnit köra minst en gång, blir bakgrunden svart igen.
Så fort `wallpaper-cycle.timer` är aktiverad läker det sig själv automatiskt
inom `OnStartupSec=2min` efter varje inloggning — men fram tills dess (systemet
är byggt men inte aktiverat, se [[../04-tema/dynamiskt-tema]] "Kvarstår") är
det här en känd svag punkt.
