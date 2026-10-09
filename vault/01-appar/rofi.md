# rofi

App-launcher. `config.rasi` (inställningar) + `colors.rasi` (separat färgtema-fil,
[[../04-tema/design|samma palett]] som resten av riggen).

## Musklick

Rofi startar normalt en app först vid dubbelklick, och ett enkelt klick
markerar bara. Jakob upplevde att ikonerna inte gick att klicka på. Sedan
2026-10-09 startar ett enkelt klick appen (`me-accept-entry: "MousePrimary"`,
`me-select-entry: ""`), och `hover-select: true` markerar ikonen musen är över.
