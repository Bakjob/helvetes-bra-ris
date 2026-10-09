# eww tappade all styling efter å/ä/ö i eww.scss

**2026-10-09.** När VPN-raden lades till i wifi-menyn fick `eww.scss` en kommentar
med å/ä/ö ("ikonen först, guld när VPN är på"). eww laddade om filen och då föll
**hela** stilmallen bort. Menyerna visades med GTK:s standardutseende (grå
bakgrund, ingen kortdesign) och inget fel syntes i loggen.

**Fix:** skriv kommentaren bara med ASCII. Stilen kom tillbaka direkt när filen
sparades, utan omstart av eww.

**Regel:** håll `eww/eww.scss` helt ASCII. Det är därför de äldre kommentarerna
där skriver "langst till hoger" osv. Snabbkoll:
`grep -nP '[^\x00-\x7F]' eww/eww.scss` ska inte ge någon träff.

Se [[vault/01-appar/eww]].
