# helvetes bra ris

Jakobs rice/dotfiles för en **EndeavourOS + Hyprland**-rigg. Allt i det här repot är
symlinkat direkt till `~/.config/<namn>` (eller `~/.bashrc`) på den körande datorn —
det som ligger här är alltså exakt det som faktiskt används, inte en kopia.

## Vad som finns här

| Mapp/fil | Symlinkad till | Program |
|---|---|---|
| `hypr/` | `~/.config/hypr` | Hyprland (lua-config) |
| `kitty/` | `~/.config/kitty` | terminal |
| `waybar/` | `~/.config/waybar` | statusbar |
| `eww/` | `~/.config/eww` | widgets |
| `rofi/` | `~/.config/rofi` | app-launcher |
| `swaync/` | `~/.config/swaync` | notiser |
| `wlogout/` | `~/.config/wlogout` | power-meny |
| `wob/` | `~/.config/wob` | volym/ljusstyrka-OSD |
| `cava/` | `~/.config/cava` | ljudvisualisering (i waybar) |
| `btop/` | `~/.config/btop` | systemmonitor |
| `fastfetch/` | `~/.config/fastfetch` | systeminfo-fetch |
| `starship.toml` | `~/.config/starship.toml` | shell-prompt |
| `bashrc` | `~/.bashrc` | shell |
| `spicetify/Themes/SvenskSkog/` | `~/.config/spicetify/Themes/SvenskSkog` | Spotify-tema (via spicetify-cli) |
| `wallust/` | `~/.config/wallust` | dynamiskt tema per bakgrundsbild |
| `systemd/user/*.{service,timer}` | enskilda filer i `~/.config/systemd/user/` | `wallpaper-cycle` (bakgrundsbyte varje heltimme) |

## vault/

En Obsidian-kompatibel anteckningssamling om hela riggen: varför saker är
konfigurerade som de är, beslut som tagits, kända problem, tema/färgval. Fungerar
direkt som vanlig Markdown, men öppnas gärna som ett Obsidian-valv. Se
[`vault/README.md`](vault/README.md) för strukturen och
[`vault/02-beslut/changelog.md`](vault/02-beslut/changelog.md) för historiken.

## CLAUDE.md

Repot underhålls delvis tillsammans med [Claude Code](https://claude.com/claude-code).
[`CLAUDE.md`](CLAUDE.md) beskriver spelreglerna för det (t.ex. att aldrig reloada eller
starta om komponenter i den körande sessionen utan att fråga först).
