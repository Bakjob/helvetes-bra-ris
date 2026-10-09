#!/usr/bin/env bash
# Roterar bakgrundsbild (varje heltimme, styrs av systemd/wallpaper-cycle.timer)
# och drar ett nytt tema ur den nya bilden med wallust - utom för ankarbilden,
# som återställer den handgjorda Svensk skog-paletten från wallust/anchor/.
# Se vault/04-tema/dynamiskt-tema.md för hela arkitekturen.
#
# Körs som ett systemd --user oneshot-jobb (inte en egen sleep-loop) - undviker
# den läckande bakgrundsprocess-bugg vi hittade i cava/wob/ac-sound-watch
# tidigare (se vault/03-felsokning/cava-process-lacka.md): ingen kvardröjande
# process att glömma bort.
set -euo pipefail

DOTFILES="$HOME/dotfiles"
BG_DIR="$DOTFILES/images/backgrounds"
STATE_FILE="$HOME/.cache/dotfiles-wallpaper-index"
CURRENT_LINK="$BG_DIR/.current.jpg"
ANCHOR_IMAGE="höstskog-1.jpg"

# Samma filnamnsordning som hyprpaper tidigare använde med order=default.
mapfile -t IMAGES < <(find "$BG_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%f\n' | sort)
count=${#IMAGES[@]}

if [ "$count" -eq 0 ]; then
    echo "Inga bakgrundsbilder hittades i $BG_DIR" >&2
    exit 1
fi

last=-1
[ -f "$STATE_FILE" ] && last=$(cat "$STATE_FILE")
next=$(( (last + 1) % count ))
echo "$next" > "$STATE_FILE"

image="${IMAGES[$next]}"
image_path="$BG_DIR/$image"
echo "Bakgrundsbyte: $image ($((next + 1))/$count)"

ln -sf "$image_path" "$CURRENT_LINK"

if [ "$image" = "$ANCHOR_IMAGE" ]; then
    echo "Ankarbild - återställer Svensk skog-paletten från wallust/anchor/"
    cp "$DOTFILES/wallust/anchor/waybar-colors.css" "$DOTFILES/waybar/colors.css"
    cp "$DOTFILES/wallust/anchor/kitty-colors.conf" "$DOTFILES/kitty/colors.conf"
    cp "$DOTFILES/wallust/anchor/swaync-colors.css" "$DOTFILES/swaync/colors.css"
    cp "$DOTFILES/wallust/anchor/hypr-colors.lua" "$DOTFILES/hypr/colors.lua"
    cp "$DOTFILES/wallust/anchor/rofi-colors.rasi" "$DOTFILES/rofi/colors.rasi"
    cp "$DOTFILES/wallust/anchor/eww-colors.scss" "$DOTFILES/eww/colors.scss"
else
    echo "Genererar tema med wallust..."
    wallust run "$image_path" --skip-sequences --quiet
fi

# hyprpaper cachar sin bildväg vid start och har inget skriptbart IPC (bara
# ett binärt Hyprwire-protokoll, ingen text-hyprctl) - enda tillförlitliga
# sättet att byta bild är att döda och starta om den. Den startas via
# Hyprland (hyprctl dispatch exec_cmd), inte direkt härifrån: annars hamnar
# den i den här systemd-tjänstens cgroup istället för i sessionen.
pkill -x hyprpaper 2>/dev/null || true
sleep 0.3
hyprctl dispatch 'hl.dsp.exec_cmd("hyprpaper")' >/dev/null 2>&1 || true

# Kantfärgerna (hypr/colors.lua) kräver en reload. Den nollställer
# runtime-inställningar, så valda skärmeffekter laddas igen efteråt.
hyprctl reload >/dev/null 2>&1 || true
"$DOTFILES/hypr/scripts/effects.sh" apply || true

# waybar och swaync laddas bara om, de startas inte om. En omstart av swaync
# stängde av Stör ej och tömde notishistoriken varje timme. SIGUSR2 = waybar
# läser om config + CSS (och därmed colors.css). Kör waybar inte alls startas
# den via Hyprland. eww läser om colors.scss själv när filen ändras.
if pgrep -x waybar >/dev/null; then
    pkill -SIGUSR2 -x waybar || true
else
    hyprctl dispatch 'hl.dsp.exec_cmd("waybar")' >/dev/null 2>&1 || true
fi

if pgrep -x swaync >/dev/null; then
    swaync-client --reload-css >/dev/null 2>&1 || true
else
    hyprctl dispatch 'hl.dsp.exec_cmd("swaync")' >/dev/null 2>&1 || true
fi

# Befintliga kitty-fönster behåller sina färger tills de stängs (eller
# ctrl+shift+f5 manuellt) - nya fönster som öppnas efter det här får de
# uppdaterade färgerna automatiskt.
echo "Klart."
