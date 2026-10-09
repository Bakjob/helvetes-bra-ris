// Skärmeffekter för Hyprlands screen_shader - MALL, används inte direkt.
//
// hypr/scripts/effects.sh sätter ihop den riktiga shadern: lägger till
// `#version 300 es` och en `#define FX_<NAMN>` per vald effekt överst, plus
// FX_TIME om någon vald effekt är rörlig. Resultatet skrivs till ~/.cache och
// laddas live med hyprctl. Alla effekter kan kombineras. Väljs i eww-galleriet
// "Effekter" (inställningspanelen) eller med Super+Shift+W (regn).
//
// Stillastående effekter (ingen `uniform float time`) är i princip gratis:
// Hyprland ritar bara om det som ändras. Rörliga effekter kräver
// debug:damage_tracking = 0, dvs hela skärmen ritas om 60 ggr/s - mätt ~1,9 W
// extra med rörligt regn (2026-10-09). Se vault/04-tema/skarmeffekter.md.
//
// Koordinater: uv = v_texcoord (0..1, y = 0 överst), q = uv med rätt
// bildförhållande (x * ASPECT). Allt nedan är fritt justerbart.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

#ifdef FX_TIME
uniform float time;
#else
const float time = 37.0; // stillastående: en fryst tidpunkt
#endif

const float ASPECT = 1.5;                   // 2256x1504
const vec2  SCREEN = vec2(2256.0, 1504.0);  // för filmkornet (en korn per pixel)

// ---------- Höstljus (gradering) ----------
const float GRADE_DESATURATE = 0.15;  // 0 = orörd mättnad
const vec3  GRADE_SHADOWS    = vec3(1.05, 0.98, 0.88);  // varma skuggor
const vec3  GRADE_MIDS_MOSS  = vec3(0.96, 1.03, 0.90);  // mossgrön dragning i mellantoner
const float GRADE_VIGNETTE   = 0.28;

// ---------- Kvällsläge ----------
const float EVENING_DARKEN = 0.82;
const vec3  EVENING_TINT   = vec3(0.86, 0.92, 1.08);

// ---------- Markdimma / drivande dimma ----------
const vec3  FOG_COLOR      = vec3(0.72, 0.75, 0.70);
const float GROUNDFOG_AMT  = 0.60;  // hur tät nere vid kanten
const float DRIFTFOG_AMT   = 0.50;
const float DRIFTFOG_SPEED = 0.025;

// ---------- Filmkorn ----------
const float GRAIN_AMT = 0.06;

// ---------- Frost ----------
const float FROST_REACH = 0.70;  // hur långt in från hörnen (0-1, lägre = längre in)
const vec3  FROST_COLOR = vec3(0.86, 0.91, 0.94);

// ---------- Fallande löv ----------
const float LEAF_COLUMNS = 8.0;
const float LEAF_CHANCE  = 0.75;
const float LEAF_SPEED   = 0.05;
const float LEAF_SIZE    = 0.024;

// ---------- Eldflugor ----------
const float FLY_SCALE  = 6.0;    // rutnät (högre = fler)
const float FLY_CHANCE = 0.45;
const vec3  FLY_COLOR  = vec3(1.0, 0.82, 0.38);

// ---------- Snö ----------
const float SNOW_AMT = 0.85;

// ---------- Regn ----------
const float RAIN_SMALL_SCALE   = 22.0;
const float RAIN_SMALL_CHANCE  = 0.35;
const float RAIN_MEDIUM_SCALE  = 11.0;
const float RAIN_MEDIUM_CHANCE = 0.25;
const float RAIN_LIFE_SPEED    = 0.05;
const float RAIN_COLUMNS       = 9.0;
const float RAIN_RUN_CHANCE    = 0.5;
const float RAIN_RUN_SPEED     = 0.06;
const float RAIN_REFRACTION    = 1.6;
const float RAIN_HIGHLIGHT     = 0.30;
const float RAIN_RIM           = 0.22;
const float RAIN_MIST          = 0.14;
const vec3  RAIN_MIST_COLOR    = vec3(0.74, 0.77, 0.73);
const float RAIN_DARKEN        = 0.90;

// ================= Hjälpfunktioner =================

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

// ================= Regn =================

// Stillastående droppar: (förskjutning.xy, mask, glans)
vec4 rainStatic(vec2 q, float scale, float chance, float seed) {
    vec2 p = q * scale;
    vec2 cell = floor(p);
    vec2 f = fract(p) - 0.5;
    float n = hash(cell + seed);
    if (n > chance) return vec4(0.0);
    vec2 center = (vec2(hash(cell + seed + 3.1), hash(cell + seed + 7.7)) - 0.5) * 0.5;
    float r = mix(0.14, 0.30, hash(cell + seed + 11.3));
    float life = fract(time * RAIN_LIFE_SPEED + hash(cell + seed + 5.9));
    float fade = smoothstep(0.0, 0.04, life) * smoothstep(1.0, 0.6, life);
    vec2 d = f - center;
    float m = smoothstep(r, r * 0.8, length(d)) * fade;
    float hl = smoothstep(r * 0.35, 0.0, length(d + r * vec2(0.35, 0.40))) * fade;
    return vec4(-d / scale * m * RAIN_REFRACTION, m, hl);
}

// Rinnande droppar med spår av småpärlor. clearPath = torkad strimma i disen.
vec4 rainRunners(vec2 q, out float clearPath) {
    clearPath = 0.0;
    float x = q.x * RAIN_COLUMNS;
    float col = floor(x);
    float n = hash(vec2(col, 17.0));
    if (n > RAIN_RUN_CHANCE) return vec4(0.0);
    float speed = RAIN_RUN_SPEED * mix(0.6, 1.4, hash(vec2(col, 23.0)));
    float y = fract(time * speed + n * 9.0) * 1.4 - 0.2;
    float sway = 0.12 * sin(q.y * 9.0 + n * 6.28);
    float dx = (fract(x) - 0.5 - sway) / RAIN_COLUMNS;
    float dy = q.y - y;
    float R = mix(0.016, 0.024, hash(vec2(col, 31.0)));
    vec2 d = vec2(dx, dy * 0.8);
    float m = smoothstep(R, R * 0.75, length(d));
    float hl = smoothstep(R * 0.4, 0.0, length(d + R * vec2(0.3, 0.4)));
    vec2 offset = -d * m * RAIN_REFRACTION * 0.9;
    float behind = -dy;
    if (behind > 0.0 && behind < 0.3) {
        float tfade = 1.0 - behind / 0.3;
        float spacing = 0.04;
        float ty = (fract(behind / spacing) - 0.5) * spacing;
        vec2 td = vec2(dx, ty);
        float tr = 0.0055 * tfade + 0.001;
        float mt = smoothstep(tr, tr * 0.6, length(td)) * tfade;
        offset += -td * mt * RAIN_REFRACTION;
        m = max(m, mt);
        clearPath = smoothstep(0.012, 0.0, abs(dx)) * tfade;
    }
    return vec4(offset, m, hl);
}

// ================= Färg/ljus-effekter =================

vec3 fxGrade(vec3 c, vec2 uv) {
    float l = luma(c);
    c = mix(vec3(l), c, 1.0 - GRADE_DESATURATE);
    c *= mix(GRADE_SHADOWS, vec3(1.0), smoothstep(0.0, 0.6, l));
    float mids = 1.0 - abs(l - 0.5) * 2.0;
    c = mix(c, c * GRADE_MIDS_MOSS, mids);
    c = mix(c, smoothstep(0.0, 1.0, c), 0.15);  // lite mjuk kontrast
    float v = distance(uv, vec2(0.5)) * 1.3;
    return c * (1.0 - GRADE_VIGNETTE * v * v);
}

vec3 fxEvening(vec3 c) {
    float l = luma(c);
    c = mix(vec3(l), c, 0.8);
    return c * EVENING_TINT * EVENING_DARKEN;
}

vec3 fxGroundFog(vec3 c, vec2 uv, vec2 q) {
    float band = smoothstep(0.40, 1.0, uv.y);
    float n = valueNoise(q * vec2(2.5, 7.0)) * 0.6 + valueNoise(q * vec2(6.0, 14.0)) * 0.4;
    return mix(c, FOG_COLOR, GROUNDFOG_AMT * band * (0.45 + 0.55 * n));
}

vec3 fxDriftFog(vec3 c, vec2 uv, vec2 q) {
    float band = 0.35 + 0.65 * smoothstep(0.2, 1.0, uv.y);
    vec2 drift = vec2(time * DRIFTFOG_SPEED, time * DRIFTFOG_SPEED * 0.3);
    float n = valueNoise(q * 2.0 + drift) * 0.6 + valueNoise(q * 4.5 - drift * 1.7) * 0.4;
    n = smoothstep(0.35, 0.85, n);
    return mix(c, FOG_COLOR, DRIFTFOG_AMT * band * n);
}

vec3 fxGrain(vec3 c, vec2 uv) {
    float g = hash(floor(uv * SCREEN)) - 0.5;  // stillastående korn, även i rörligt läge
    float l = luma(c);
    float midWeight = 0.5 + 2.0 * l * (1.0 - l);  // mest korn i mellantonerna
    return c + g * GRAIN_AMT * midWeight;
}

vec3 fxFrost(vec3 c, vec2 uv, vec2 q) {
    vec2 p = (uv - 0.5) * vec2(ASPECT, 1.0);
    float r = length(p) / length(vec2(0.5 * ASPECT, 0.5));  // 1 i hörnen
    float k = smoothstep(FROST_REACH, 1.0, r);
    // Rafflat brus i tre skalor (1 - |2n - 1| ger tunna åsar) = kristallstruktur.
    // Frosten "växer" in från hörnen: tröskeln sjunker ju närmare hörnet,
    // och strukturen gör kanten fransig istället för en rund fläck.
    float f = (1.0 - abs(valueNoise(q * 22.0) * 2.0 - 1.0)) * 0.45
            + (1.0 - abs(valueNoise(q * 55.0 + 3.7) * 2.0 - 1.0)) * 0.35
            + (1.0 - abs(valueNoise(q * 130.0 + 9.1) * 2.0 - 1.0)) * 0.20;
    float grow = k * 1.25 - 0.25 + (f - 0.6) * 0.7;
    float m = smoothstep(0.0, 0.18, grow);
    c = mix(c, FROST_COLOR, m * (0.30 + 0.40 * f));
    return c + vec3(0.04, 0.05, 0.06) * k;  // kall ljusning mot hörnen
}

// ================= Rörliga partiklar =================

vec3 fxLeaves(vec3 c, vec2 q) {
    for (int layer = 0; layer < 2; layer++) {
        float fl = float(layer);
        float cols = LEAF_COLUMNS - fl * 3.0;
        float x = q.x * cols + fl * 0.37;
        float col = floor(x);
        float n = hash(vec2(col, 3.0 + fl * 11.0));
        if (n > LEAF_CHANCE) continue;
        float speed = LEAF_SPEED * mix(0.7, 1.3, hash(vec2(col, 5.0 + fl)));
        float y = fract(time * speed + n * 7.0) * 1.3 - 0.15;
        float sway = 0.28 * sin(time * 0.9 + n * 6.28 + y * 6.0);
        vec2 d = vec2((fract(x) - 0.5 - sway) / cols, q.y - y);
        float ang = time * mix(0.8, 1.8, n) + n * 6.28;
        mat2 rot = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
        vec2 p = rot * d;
        float size = LEAF_SIZE * mix(0.8, 1.3, hash(vec2(col, 9.0 + fl)));
        // spetsig bladform: ellips som smalnar av mot ändarna
        float w = size * 0.5 * (1.0 - pow(abs(p.x) / size, 2.0));
        float inside = step(abs(p.x), size) * smoothstep(w, w * 0.6, abs(p.y));
        float pick = hash(vec2(col, 13.0 + fl));
        vec3 leafCol = pick < 0.33 ? vec3(0.80, 0.55, 0.20)     // guld
                     : pick < 0.66 ? vec3(0.62, 0.28, 0.16)     // rost
                     :               vec3(0.45, 0.32, 0.18);    // brunt
        leafCol *= 0.85 + 0.3 * step(abs(p.y), size * 0.04);   // mittnerv
        c = mix(c, leafCol, inside * 0.9);
    }
    return c;
}

vec3 fxFireflies(vec3 c, vec2 uv, vec2 q) {
    vec2 p = q * FLY_SCALE;
    vec2 cell = floor(p);
    float n = hash(cell + 51.0);
    if (n > FLY_CHANCE) return c;
    vec2 center = 0.5 + 0.30 * vec2(sin(time * mix(0.2, 0.5, n) + n * 6.28),
                                    cos(time * mix(0.15, 0.4, hash(cell + 7.0)) + n * 3.1));
    float dist = length(fract(p) - center) / FLY_SCALE;
    float pulse = pow(0.5 + 0.5 * sin(time * mix(0.8, 1.6, hash(cell + 3.0)) + n * 20.0), 3.0);
    float glow = exp(-dist * dist / 0.00003) + 0.35 * exp(-dist * dist / 0.0004);
    float lower = smoothstep(0.15, 0.55, uv.y);  // mest nere vid "marken"
    return c + FLY_COLOR * glow * pulse * lower;
}

vec3 fxSnow(vec3 c, vec2 q) {
    for (int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float scale = 10.0 + fl * 8.0;
        float speed = 0.05 - fl * 0.012;
        vec2 p = q * scale + vec2(sin(time * 0.4 + fl) * 0.5, -time * speed * scale);
        vec2 cell = floor(p);
        float n = hash(cell + fl * 31.0);
        if (n > 0.45) continue;
        vec2 center = vec2(hash(cell + 1.7 + fl), hash(cell + 4.2 + fl)) * 0.6 + 0.2;
        float d = length(fract(p) - center);
        float r = mix(0.06, 0.12, hash(cell + 8.8)) * (1.0 - fl * 0.2);
        float flake = smoothstep(r, r * 0.3, d);
        c = mix(c, vec3(0.95, 0.97, 1.0), flake * SNOW_AMT * (1.0 - fl * 0.25));
    }
    return c;
}

// ================= Huvudprogram =================

void main() {
    vec2 uv = v_texcoord;
    vec2 q = vec2(uv.x * ASPECT, uv.y);
    vec2 sampleUv = uv;

#ifdef FX_RAIN
    float clearPath = 0.0;
    vec4 ra = rainStatic(q, RAIN_SMALL_SCALE, RAIN_SMALL_CHANCE, 0.0);
    vec4 rb = rainStatic(q, RAIN_MEDIUM_SCALE, RAIN_MEDIUM_CHANCE, 41.0);
    vec4 rc = rainRunners(q, clearPath);
    vec2 rainOffset = ra.xy + rb.xy + rc.xy;
    float rainMask = clamp(ra.z + rb.z + rc.z, 0.0, 1.0);
    float rainGlare = clamp(ra.w + rb.w + rc.w, 0.0, 1.0);
    sampleUv = clamp(uv + vec2(rainOffset.x / ASPECT, rainOffset.y), 0.0, 1.0);
#endif

    vec4 color = texture(tex, sampleUv);
    vec3 c = color.rgb;

#ifdef FX_GRADE
    c = fxGrade(c, uv);
#endif
#ifdef FX_EVENING
    c = fxEvening(c);
#endif
#ifdef FX_GROUNDFOG
    c = fxGroundFog(c, uv, q);
#endif
#ifdef FX_DRIFTFOG
    c = fxDriftFog(c, uv, q);
#endif
#ifdef FX_RAIN
    float mist = valueNoise(q * 2.2 + vec2(time * 0.015, time * 0.01)) * 0.65
               + valueNoise(q * 5.0 - vec2(time * 0.02, 0.0)) * 0.35;
    c = mix(c, RAIN_MIST_COLOR, RAIN_MIST * mist * (1.0 - rainMask) * (1.0 - 0.8 * clearPath));
    c *= 1.0 - RAIN_RIM * rainMask * (1.0 - rainMask) * 4.0;
    c += RAIN_HIGHLIGHT * rainGlare;
    c *= RAIN_DARKEN;
#endif
#ifdef FX_FROST
    c = fxFrost(c, uv, q);
#endif
#ifdef FX_LEAVES
    c = fxLeaves(c, q);
#endif
#ifdef FX_SNOW
    c = fxSnow(c, q);
#endif
#ifdef FX_FIREFLIES
    c = fxFireflies(c, uv, q);
#endif
#ifdef FX_GRAIN
    c = fxGrain(c, uv);
#endif

    fragColor = vec4(clamp(c, 0.0, 1.0), color.a);
}
