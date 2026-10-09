#!/usr/bin/env python3
"""Renderar förhandsbilder till eww-galleriet "Effekter".

Python/numpy-kopia av matten i hypr/shaders/effects.glsl - HÅLL I SYNK om
konstanterna eller effekterna ändras där. Renderas mot ankarbakgrunden i full
skärmupplösning, beskärs per effekt (så att t.ex. frost i hörnet och korn på
pixelnivå syns i en liten bild) och sparas som 360x240 PNG med rundade hörn i
images/effect-previews/. Kräver numpy + ImageMagick (`magick`).

    python3 hypr/scripts/render-effect-previews.py
"""
import os
import subprocess
import tempfile

import numpy as np

DOTFILES = os.path.expanduser("~/dotfiles")
SRC = os.path.join(DOTFILES, "images/backgrounds/höstskog-1.jpg")
OUT = os.path.join(DOTFILES, "images/effect-previews")
W, H = 2256, 1504
ASPECT = 1.5
THUMB = (360, 240)

# --- samma konstanter som i effects.glsl ---
GRADE_DESATURATE, GRADE_SHADOWS, GRADE_MIDS_MOSS, GRADE_VIGNETTE = 0.15, (1.05, 0.98, 0.88), (0.96, 1.03, 0.90), 0.28
EVENING_DARKEN, EVENING_TINT = 0.82, (0.86, 0.92, 1.08)
FOG_COLOR, GROUNDFOG_AMT, DRIFTFOG_AMT, DRIFTFOG_SPEED = (0.72, 0.75, 0.70), 0.60, 0.50, 0.025
GRAIN_AMT = 0.06
FROST_REACH, FROST_COLOR = 0.70, (0.86, 0.91, 0.94)
LEAF_COLUMNS, LEAF_CHANCE, LEAF_SPEED, LEAF_SIZE = 8.0, 0.75, 0.05, 0.024
FLY_SCALE, FLY_CHANCE, FLY_COLOR = 6.0, 0.45, (1.0, 0.82, 0.38)
SNOW_AMT = 0.85
RAIN = dict(small_scale=22.0, small_chance=0.35, medium_scale=11.0, medium_chance=0.25, life=0.05,
            cols=9.0, run_chance=0.5, run_speed=0.06, refr=1.6, hl=0.30, rim=0.22, mist=0.14,
            mist_color=(0.74, 0.77, 0.73), darken=0.90)


def fract(x):
    return x - np.floor(x)


def hash2(x, y):
    px, py = fract(x * 123.34), fract(y * 456.21)
    d = px * (px + 45.32) + py * (py + 45.32)
    px, py = px + d, py + d
    return fract(px * py)


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def vnoise(x, y):
    ix, iy = np.floor(x), np.floor(y)
    fx, fy = x - ix, y - iy
    ux, uy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy), hash2(ix + 1, iy)
    c, d = hash2(ix, iy + 1), hash2(ix + 1, iy + 1)
    return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy


def luma(c):
    return c[..., 0] * 0.299 + c[..., 1] * 0.587 + c[..., 2] * 0.114


def mix(a, b, t):
    return a + (b - a) * (t[..., None] if np.ndim(t) == 2 else t)


def load_image():
    raw = subprocess.run(["magick", SRC, "-resize", f"{W}x{H}^", "-gravity", "center",
                          "-extent", f"{W}x{H}", "-depth", "8", "rgb:-"],
                         check=True, capture_output=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(H, W, 3).astype(np.float64) / 255


yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
U, V = (xx + 0.5) / W, (yy + 0.5) / H
QX, QY = U * ASPECT, V


def sample(img, su, sv):
    return img[np.clip((sv * H).astype(int), 0, H - 1), np.clip((su * W).astype(int), 0, W - 1)]


def fx_grade(c):
    l = luma(c)
    c = mix(l[..., None].repeat(3, -1), c, 1 - GRADE_DESATURATE)
    c = c * mix(np.array(GRADE_SHADOWS), np.ones(3), ss(0, 0.6, l))
    mids = 1 - np.abs(l - 0.5) * 2
    c = mix(c, c * np.array(GRADE_MIDS_MOSS), mids)
    c = mix(c, ss(0, 1, c), 0.15)
    v = np.hypot(U - 0.5, V - 0.5) * 1.3
    return c * (1 - GRADE_VIGNETTE * v * v)[..., None]


def fx_evening(c):
    l = luma(c)
    c = mix(l[..., None].repeat(3, -1), c, 0.8)
    return c * np.array(EVENING_TINT) * EVENING_DARKEN


def fx_groundfog(c):
    band = ss(0.4, 1.0, V)
    n = vnoise(QX * 2.5, QY * 7.0) * 0.6 + vnoise(QX * 6.0, QY * 14.0) * 0.4
    return mix(c, np.array(FOG_COLOR), GROUNDFOG_AMT * band * (0.45 + 0.55 * n))


def fx_driftfog(c, t):
    band = 0.35 + 0.65 * ss(0.2, 1.0, V)
    dx, dy = t * DRIFTFOG_SPEED, t * DRIFTFOG_SPEED * 0.3
    n = vnoise(QX * 2 + dx, QY * 2 + dy) * 0.6 + vnoise(QX * 4.5 - dx * 1.7, QY * 4.5 - dy * 1.7) * 0.4
    return mix(c, np.array(FOG_COLOR), DRIFTFOG_AMT * band * ss(0.35, 0.85, n))


def fx_grain(c):
    g = hash2(np.floor(U * W), np.floor(V * H)) - 0.5
    l = luma(c)
    return c + (g * GRAIN_AMT * (0.5 + 2 * l * (1 - l)))[..., None]


def fx_frost(c):
    r = np.hypot((U - 0.5) * ASPECT, V - 0.5) / np.hypot(0.5 * ASPECT, 0.5)
    k = ss(FROST_REACH, 1.0, r)
    f = ((1 - np.abs(vnoise(QX * 22, QY * 22) * 2 - 1)) * 0.45
         + (1 - np.abs(vnoise(QX * 55 + 3.7, QY * 55 + 3.7) * 2 - 1)) * 0.35
         + (1 - np.abs(vnoise(QX * 130 + 9.1, QY * 130 + 9.1) * 2 - 1)) * 0.20)
    grow = k * 1.25 - 0.25 + (f - 0.6) * 0.7
    m = ss(0, 0.18, grow)
    c = mix(c, np.array(FROST_COLOR), m * (0.30 + 0.40 * f))
    return c + np.array([0.04, 0.05, 0.06]) * k[..., None]


def fx_leaves(c, t):
    for layer in range(2):
        cols = LEAF_COLUMNS - layer * 3
        x = QX * cols + layer * 0.37
        col = np.floor(x)
        n = hash2(col, np.full_like(col, 3.0 + layer * 11))
        on = n <= LEAF_CHANCE
        speed = LEAF_SPEED * (0.7 + 0.6 * hash2(col, np.full_like(col, 5.0 + layer)))
        y = fract(t * speed + n * 7) * 1.3 - 0.15
        sway = 0.28 * np.sin(t * 0.9 + n * 6.28 + y * 6)
        dx, dy = (fract(x) - 0.5 - sway) / cols, QY - y
        ang = t * (0.8 + n) + n * 6.28
        # GLSL mat2(a,b,c,d) är kolumnvis: rot * d = (a*dx + c*dy, b*dx + d*dy)
        px = np.cos(ang) * dx + np.sin(ang) * dy
        py = -np.sin(ang) * dx + np.cos(ang) * dy
        size = LEAF_SIZE * (0.8 + 0.5 * hash2(col, np.full_like(col, 9.0 + layer)))
        w = size * 0.5 * (1 - (np.abs(px) / size) ** 2)
        inside = (np.abs(px) <= size) * ss(w, w * 0.6, np.abs(py)) * on
        pick = hash2(col, np.full_like(col, 13.0 + layer))
        leaf = np.where((pick < 0.33)[..., None], [0.80, 0.55, 0.20],
                        np.where((pick < 0.66)[..., None], [0.62, 0.28, 0.16], [0.45, 0.32, 0.18]))
        leaf = leaf * (0.85 + 0.3 * (np.abs(py) <= size * 0.04))[..., None]
        c = mix(c, leaf, inside * 0.9)
    return c


def fx_fireflies(c, t):
    px, py = QX * FLY_SCALE, QY * FLY_SCALE
    cx, cy = np.floor(px), np.floor(py)
    n = hash2(cx + 51, cy + 51)
    on = n <= FLY_CHANCE
    ctrx = 0.5 + 0.30 * np.sin(t * (0.2 + 0.3 * n) + n * 6.28)
    ctry = 0.5 + 0.30 * np.cos(t * (0.15 + 0.25 * hash2(cx + 7, cy + 7)) + n * 3.1)
    dist = np.hypot(fract(px) - ctrx, fract(py) - ctry) / FLY_SCALE
    pulse = (0.5 + 0.5 * np.sin(t * (0.8 + 0.8 * hash2(cx + 3, cy + 3)) + n * 20)) ** 3
    glow = np.exp(-dist ** 2 / 0.00003) + 0.35 * np.exp(-dist ** 2 / 0.0004)
    return c + np.array(FLY_COLOR) * (glow * pulse * ss(0.15, 0.55, V) * on)[..., None]


def fx_snow(c, t):
    for layer in range(3):
        scale = 10 + layer * 8
        speed = 0.05 - layer * 0.012
        px = QX * scale + np.sin(t * 0.4 + layer) * 0.5
        py = QY * scale - t * speed * scale
        cx, cy = np.floor(px), np.floor(py)
        n = hash2(cx + layer * 31, cy + layer * 31)
        on = n <= 0.45
        ctrx = hash2(cx + 1.7 + layer, cy + 1.7 + layer) * 0.6 + 0.2
        ctry = hash2(cx + 4.2 + layer, cy + 4.2 + layer) * 0.6 + 0.2
        d = np.hypot(fract(px) - ctrx, fract(py) - ctry)
        r = (0.06 + 0.06 * hash2(cx + 8.8, cy + 8.8)) * (1 - layer * 0.2)
        flake = ss(r, r * 0.3, d) * on
        c = mix(c, np.array([0.95, 0.97, 1.0]), flake * SNOW_AMT * (1 - layer * 0.25))
    return c


def rain_static(scale, chance, seed, t):
    px, py = QX * scale, QY * scale
    cx, cy = np.floor(px), np.floor(py)
    fx, fy = px - cx - 0.5, py - cy - 0.5
    on = hash2(cx + seed, cy + seed) <= chance
    ccx = (hash2(cx + seed + 3.1, cy + seed + 3.1) - 0.5) * 0.5
    ccy = (hash2(cx + seed + 7.7, cy + seed + 7.7) - 0.5) * 0.5
    r = 0.14 + 0.16 * hash2(cx + seed + 11.3, cy + seed + 11.3)
    life = fract(t * RAIN["life"] + hash2(cx + seed + 5.9, cy + seed + 5.9))
    fade = ss(0, 0.04, life) * ss(1, 0.6, life)
    dx, dy = fx - ccx, fy - ccy
    m = ss(r, r * 0.8, np.hypot(dx, dy)) * fade * on
    hl = ss(r * 0.35, 0, np.hypot(dx + r * 0.35, dy + r * 0.4)) * fade * on
    return -dx / scale * m * RAIN["refr"], -dy / scale * m * RAIN["refr"], m, hl


def rain_runners(t):
    cols = RAIN["cols"]
    x = QX * cols
    col = np.floor(x)
    n = hash2(col, np.full_like(col, 17.0))
    on = n <= RAIN["run_chance"]
    speed = RAIN["run_speed"] * (0.6 + 0.8 * hash2(col, np.full_like(col, 23.0)))
    y = fract(t * speed + n * 9) * 1.4 - 0.2
    sway = 0.12 * np.sin(QY * 9 + n * 6.28)
    dx, dy = (fract(x) - 0.5 - sway) / cols, QY - y
    R = 0.016 + 0.008 * hash2(col, np.full_like(col, 31.0))
    m = ss(R, R * 0.75, np.hypot(dx, dy * 0.8))
    hl = ss(R * 0.4, 0, np.hypot(dx + R * 0.3, dy * 0.8 + R * 0.4))
    ox, oy = -dx * m * RAIN["refr"] * 0.9, -dy * 0.8 * m * RAIN["refr"] * 0.9
    beh = -dy
    inn = (beh > 0) & (beh < 0.3)
    tf = np.where(inn, 1 - beh / 0.3, 0)
    ty = (fract(beh / 0.04) - 0.5) * 0.04
    tr = 0.0055 * tf + 0.001
    mt = ss(tr, tr * 0.6, np.hypot(dx, ty)) * tf * inn
    ox, oy = ox - dx * mt * RAIN["refr"], oy - ty * mt * RAIN["refr"]
    m = np.maximum(m, mt)
    clear = ss(0.012, 0, np.abs(dx)) * tf * inn
    return ox * on, oy * on, m * on, hl * on, clear * on


def render(img, effects, t=37.0):
    su, sv = U, V
    rain = "rain" in effects
    if rain:
        a = rain_static(RAIN["small_scale"], RAIN["small_chance"], 0.0, t)
        b = rain_static(RAIN["medium_scale"], RAIN["medium_chance"], 41.0, t)
        r = rain_runners(t)
        ox, oy = a[0] + b[0] + r[0], a[1] + b[1] + r[1]
        mask = np.clip(a[2] + b[2] + r[2], 0, 1)
        glare = np.clip(a[3] + b[3] + r[3], 0, 1)
        clear = r[4]
        su, sv = np.clip(U + ox / ASPECT, 0, 1), np.clip(V + oy, 0, 1)
    c = sample(img, su, sv)
    if "grade" in effects: c = fx_grade(c)
    if "evening" in effects: c = fx_evening(c)
    if "groundfog" in effects: c = fx_groundfog(c)
    if "driftfog" in effects: c = fx_driftfog(c, t)
    if rain:
        mist = vnoise(QX * 2.2 + t * 0.015, QY * 2.2 + t * 0.01) * 0.65 + vnoise(QX * 5 - t * 0.02, QY * 5) * 0.35
        c = mix(c, np.array(RAIN["mist_color"]), RAIN["mist"] * mist * (1 - mask) * (1 - 0.8 * clear))
        c = c * (1 - RAIN["rim"] * mask * (1 - mask) * 4)[..., None]
        c = c + RAIN["hl"] * glare[..., None]
        c = c * RAIN["darken"]
    if "frost" in effects: c = fx_frost(c)
    if "leaves" in effects: c = fx_leaves(c, t)
    if "snow" in effects: c = fx_snow(c, t)
    if "fireflies" in effects: c = fx_fireflies(c, t)
    if "grain" in effects: c = fx_grain(c)
    return np.clip(c, 0, 1)


def save_thumb(frame, crop, path):
    x, y, w, h = crop
    region = np.ascontiguousarray((frame[y:y + h, x:x + w] * 255).astype(np.uint8))
    tw, th = THUMB
    # rundade hörn via alfamask (GTK klipper inte bilder efter border-radius)
    radius = 22
    with tempfile.NamedTemporaryFile(suffix=".rgb") as f:
        f.write(region.tobytes())
        f.flush()
        subprocess.run(["magick", "-size", f"{w}x{h}", "-depth", "8", f"rgb:{f.name}",
                        "-resize", f"{tw}x{th}!",
                        "(", "-size", f"{tw}x{th}", "xc:none", "-fill", "white",
                        "-draw", f"roundrectangle 0,0 {tw - 1},{th - 1} {radius},{radius}", ")",
                        "-alpha", "off", "-compose", "CopyOpacity", "-composite", path], check=True)


# id: (effekter att rendera, tidpunkt, beskärning x,y,w,h i full upplösning)
FULL = (0, 0, W, H)
PREVIEWS = {
    "none":      ((), 37.0, FULL),
    "grade":     (("grade",), 37.0, FULL),
    "evening":   (("evening",), 37.0, FULL),
    "groundfog": (("groundfog",), 37.0, FULL),
    "grain":     (("grain",), 37.0, (900, 700, 360, 240)),
    "frost":     (("frost",), 37.0, (0, 0, 1350, 900)),
    "rain":      (("rain",), 37.0, (700, 400, 720, 480)),
    "rain_anim": (("rain",), 52.0, (700, 400, 720, 480)),
    "driftfog":  (("driftfog",), 37.0, FULL),
    "leaves":    (("leaves",), 41.0, (400, 300, 1080, 720)),
    "fireflies": (("fireflies",), 44.0, (500, 600, 1080, 720)),
    "snow":      (("snow",), 37.0, (560, 300, 1128, 752)),
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    img = load_image()
    for pid, (effects, t, crop) in PREVIEWS.items():
        frame = render(img, set(effects), t)
        save_thumb(frame, crop, os.path.join(OUT, f"{pid}.png"))
        print("renderade", pid)
