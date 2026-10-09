# eww: svensk locale i skript + @charset-bugg i SCSS (2026-09-15)

## Locale-fällan (top/free)

Systemet kör svensk locale. `top`/`free` byter då både fältnamn och
decimaltecken:

| Verktyg | Engelska (förväntat) | Svenska (verkligheten här) |
|---|---|---|
| `free` | `Mem:` | `Minne:` |
| `top` %Cpu-rad | `us, sy, ni, id, wa, hi, si, st` | `an, sy, ni, in, vä, ha, ma, st` |
| decimaler | `1.5` | `1,5` |

Ett skript som `grep`ar efter `"Mem:"` eller `awk`ar ut `id`-fältet ger tyst
fel data (eller inget alls) istället för ett kraschfel — svårare att upptäcka.
**Lösning:** tvinga `LC_ALL=C` framför `top`/`free`/liknande i alla skript som
parsar deras utskrift. Se `eww/scripts/system-stats.sh`.

## @charset-buggen i eww:s SCSS-kompilator

`eww.scss` innehöll ett kommentar-block med en svensk bokstav (ä) och en emoji
(📊). Eww kompilerar `.scss` via `grass`, som injicerar en `@charset "UTF-8";`
när källan innehåller icke-ASCII-tecken. Ewws egen efterföljande CSS-validering
känner inte igen `@charset` som en giltig at-regel och loggar:

```
error: unknown @ rule
  @charset "UTF-8";
```

Testat och bekräftat: bort med de icke-ASCII-tecknen i just den kommentaren →
felet försvann helt, ingen `@charset`-rad i output längre.

**Gäller bara `.scss`-filer eww själv kompilerar** — `waybar`/`rofi`/`swaync`
läser sin CSS direkt (inget SCSS-steg), så svenska tecken där är helt ofarliga
(redan bevisat fungera, t.ex. svensk tooltip-text i waybar). Skriv `eww.scss`
själv på ren ASCII i kommentarer för att undvika detta, oavsett om filen i
övrigt (`eww.yuck`, labels i UI:t) har svensk text — de går via en annan
körväg och påverkas inte.

**Hände igen 2026-10-09:** en kommentar med å/ä/ö till VPN-raden i wifi-menyn.
Den här gången föll **hela** stilmallen bort (menyerna visades i GTK:s
standardutseende) och inget syntes i eww-loggen. Ta bort tecknen och spara, så
laddar eww om stilen direkt utan omstart. Kolla alltid efter en ändring:
`grep -nP '[^\x00-\x7F]' eww/eww.scss` (ska inte ge någon träff).
