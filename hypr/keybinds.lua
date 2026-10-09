local mod = "SUPER"

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = 5 }))

hl.bind(mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))

hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("sh -c 'pkill waybar; sleep 0.2; waybar & hyprctl reload'"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("wlogout -b 5 -l ~/.config/wlogout/layout.json -C ~/.config/wlogout/style.css"))

-- Skärmdump av valt område → urklipp + fil + notis med "Redigera" (satty).
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))

-- Helskärmsskärmdump, samma notis+redigera-flöde
hl.bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))

-- Regn på skärmen (en av skärmeffekterna, se vault/04-tema/skarmeffekter.md -
-- övriga effekter väljs i eww-galleriet Inställningar → Effekter). Slås på/av
-- live, rör ingen config. Stillastående regn (i princip gratis). Gillar du inte den: ta bara bort den här raden.
-- Se vault/04-tema/regn-shader.md.
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/effects.sh toggle rain"))
-- Animerat (rinnande) regn - kostar ~1,9 W eftersom hela skärmen ritas om
-- 60 ggr/s. Super+Shift+W ovan ger stillastående regn, som är i princip gratis.
hl.bind(mod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/effects.sh toggle rain_anim"))

-- Flytta/ändra storlek på fönster med mus + mod
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- Lås skärmen manuellt
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Volym (wob visar overlay-bar; tak på 150% - samma gräns pavucontrol använder
-- som standard, högre än så ger allvarlig distorsion/skaderisk för högtalarna)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd-volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd-volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd-volume.sh mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

-- Ljusstyrka (wob visar overlay-bar)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd-brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/hypr/scripts/osd-brightness.sh down"), { locked = true, repeating = true })

-- Strömknapp: kort tryck öppnar power-menyn (samma som Super+Shift+E).
-- Långt tryck (systemd-logind, se logind.conf.d/) stänger av på riktigt.
-- Går via ett litet skript (inte wlogout direkt) som filtrerar bort
-- "eko"-tryckningen som knappen genererar när den väcker datorn ur vila -
-- se vault/03-felsokning/strömknapp-ekar-efter-vila.md.
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("~/.config/hypr/scripts/power-button.sh"), { locked = true })

-- Mediauppspelning
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
