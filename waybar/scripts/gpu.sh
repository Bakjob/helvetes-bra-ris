#!/bin/bash
# Intel GPU (i915/xe) busy% för waybar, via intel_gpu_top.
# Tar fyra snabba prov över ~2s och visar snittet - ger en helhetsbild
# istället för en ryckig ögonblicksbild.

out=$(timeout 4 intel_gpu_top -J -s 500 -n 4 2>/dev/null)

if [ -z "$out" ]; then
    echo '{"text": "N/A", "tooltip": "intel_gpu_top saknas eller kräver root (kör: sudo pacman -S intel-gpu-tools)"}'
    exit 0
fi

flat=$(echo "$out" | tr -d '\n')
avg=$(echo "$flat" | grep -oP '"Render/3D[^"]*"\s*:\s*\{[^}]*?"busy"\s*:\s*\K[0-9.]+' | python3 -c "
import sys
vals = [float(l) for l in sys.stdin if l.strip()]
print(f'{sum(vals)/len(vals):.1f}' if vals else '0.0')
")

printf '{"text": "%s%%", "tooltip": "Snitt över ~2s\\n\\nKlicka för detaljerad vy"}\n' "${avg:-0.0}"
