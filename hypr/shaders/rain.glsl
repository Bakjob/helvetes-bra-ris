#version 300 es
// Regn-shader — "regn på rutan"-känsla för Hyprlands screen_shader.
//
// EXPERIMENTELLT, INTE HÅRDKODAT: aktiveras/inaktiveras live via
// hypr/scripts/toggle-rain.sh (Super+Shift+W, se keybinds.lua). Ingen
// autostart, ingen permanent config-ändring. Se vault/04-tema/regn-shader.md.
//
// Version 2 (2026-10-09): mjuk dis (value noise i stället för hårda rutor),
// droppar som syns på riktigt (linsbrytning som vänder bilden, ljus glans,
// mörk kant), stillastående droppar som kommer och avdunstar, och större
// droppar som rinner ner och lämnar ett spår av småpärlor och en klarare
// strimma i disen. Fortfarande bara aritmetik + EN texturuppslagning per
// pixel - kostnaden domineras av att hela skärmen ritas om varje bildruta
// (damage tracking av), inte av själva matten här.
//
// Allt nedan är fritt justerbart utan att förstå matten:
precision highp float;

const float ASPECT          = 1.5;   // skärmens bredd/höjd (2256x1504)
const float SMALL_SCALE     = 22.0;  // rutnät för små stillastående droppar (högre = fler, mindre)
const float SMALL_CHANCE    = 0.35;  // andel rutor som har en liten droppe (0-1)
const float MEDIUM_SCALE    = 11.0;  // rutnät för mellanstora stillastående droppar
const float MEDIUM_CHANCE   = 0.25;
const float DROP_LIFE_SPEED = 0.05;  // hur fort stillastående droppar kommer/avdunstar
const float RUNNER_COLUMNS  = 9.0;   // antal "kolumner" för rinnande droppar
const float RUNNER_CHANCE   = 0.5;   // andel kolumner med en rinnande droppe
const float RUNNER_SPEED    = 0.06;  // hur fort de rinner (skärmhöjder per sekund, ungefär)
const float REFRACTION      = 1.6;   // hur kraftigt dropparna bryter/vänder bilden
const float HIGHLIGHT       = 0.30;  // glans i dropparna (0 = ingen)
const float RIM_DARKEN      = 0.22;  // mörk kant runt dropparna (0 = ingen)
const float MIST_AMOUNT     = 0.14;  // 0 = ingen dis, 1 = helt vitt
const vec3  MIST_COLOR      = vec3(0.74, 0.77, 0.73);
const float DARKEN          = 0.88;  // 1.0 = ingen mörkläggning, lägre = dunklare
const float VIGNETTE_STRENGTH = 0.30;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;
out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Mjukt brus (bilinjär interpolation mellan rutor) - ger runda, flytande
// dis-moln i stället för den gamla versionens hårda 3x3-rutor.
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

// Stillastående droppar i ett rutnät. Returnerar (förskjutning.xy, mask, glans).
// q = skärmkoordinat med rätt bildförhållande (x * ASPECT, y).
vec4 staticDrops(vec2 q, float scale, float chance, float seed) {
    vec2 p = q * scale;
    vec2 cell = floor(p);
    vec2 f = fract(p) - 0.5;

    float n = hash(cell + seed);
    if (n > chance) return vec4(0.0);

    vec2 center = (vec2(hash(cell + seed + 3.1), hash(cell + seed + 7.7)) - 0.5) * 0.5;
    float r = mix(0.14, 0.30, hash(cell + seed + 11.3));

    // Varje droppe "lever" en stund: dyker upp snabbt, avdunstar långsamt.
    float life = fract(time * DROP_LIFE_SPEED + hash(cell + seed + 5.9));
    float fade = smoothstep(0.0, 0.04, life) * smoothstep(1.0, 0.6, life);

    vec2 d = f - center;
    float m = smoothstep(r, r * 0.8, length(d)) * fade;
    float hl = smoothstep(r * 0.35, 0.0, length(d + r * vec2(0.35, 0.40))) * fade;

    // -d: dropparna fungerar som små linser och visar bilden spegelvänd
    vec2 offset = -d / scale * m * REFRACTION;
    return vec4(offset, m, hl);
}

// Rinnande droppar: en per kolumn som glider nedåt med lite sidledsvickning
// och lämnar ett spår av småpärlor. clearPath = hur mycket disen ska torkas
// bort längs spåret.
vec4 runners(vec2 q, out float clearPath) {
    clearPath = 0.0;
    float x = q.x * RUNNER_COLUMNS;
    float col = floor(x);

    float n = hash(vec2(col, 17.0));
    if (n > RUNNER_CHANCE) return vec4(0.0);

    float speed = RUNNER_SPEED * mix(0.6, 1.4, hash(vec2(col, 23.0)));
    float y = fract(time * speed + n * 9.0) * 1.4 - 0.2;

    float sway = 0.12 * sin(q.y * 9.0 + n * 6.28);
    float dx = (fract(x) - 0.5 - sway) / RUNNER_COLUMNS;
    float dy = q.y - y;

    float R = mix(0.016, 0.024, hash(vec2(col, 31.0)));
    vec2 d = vec2(dx, dy * 0.8);
    float m = smoothstep(R, R * 0.75, length(d));
    float hl = smoothstep(R * 0.4, 0.0, length(d + R * vec2(0.3, 0.4)));
    vec2 offset = -d * m * REFRACTION * 0.9;

    // Spåret ovanför droppen (mindre y = redan passerat)
    float behind = -dy;
    if (behind > 0.0 && behind < 0.3) {
        float tfade = 1.0 - behind / 0.3;
        float spacing = 0.04;
        float ty = (fract(behind / spacing) - 0.5) * spacing;
        vec2 td = vec2(dx, ty);
        float tr = 0.0055 * tfade + 0.001;
        float mt = smoothstep(tr, tr * 0.6, length(td)) * tfade;
        offset += -td * mt * REFRACTION;
        m = max(m, mt);
        clearPath = smoothstep(0.012, 0.0, abs(dx)) * tfade;
    }
    return vec4(offset, m, hl);
}

void main() {
    vec2 uv = v_texcoord;
    vec2 q = vec2(uv.x * ASPECT, uv.y);

    float clearPath;
    vec4 a = staticDrops(q, SMALL_SCALE, SMALL_CHANCE, 0.0);
    vec4 b = staticDrops(q, MEDIUM_SCALE, MEDIUM_CHANCE, 41.0);
    vec4 c = runners(q, clearPath);

    vec2 offset = a.xy + b.xy + c.xy;
    float mask = clamp(a.z + b.z + c.z, 0.0, 1.0);
    float glare = clamp(a.w + b.w + c.w, 0.0, 1.0);

    vec2 sampleUv = clamp(uv + vec2(offset.x / ASPECT, offset.y), 0.0, 1.0);
    vec4 color = texture(tex, sampleUv);

    // Dis: två lager mjukt brus som driver åt olika håll. Svagare i dropparna
    // och i spåren efter rinnande droppar (de "torkar" rutan).
    float mist = valueNoise(q * 2.2 + vec2(time * 0.015, time * 0.01)) * 0.65
               + valueNoise(q * 5.0 - vec2(time * 0.02, 0.0)) * 0.35;
    float mistAmt = MIST_AMOUNT * mist * (1.0 - mask) * (1.0 - 0.8 * clearPath);
    color.rgb = mix(color.rgb, MIST_COLOR, mistAmt);

    // Mörk kant runt dropparna + ljus glans
    float rim = mask * (1.0 - mask) * 4.0;
    color.rgb *= 1.0 - RIM_DARKEN * rim;
    color.rgb += HIGHLIGHT * glare;

    float vignette = 1.0 - VIGNETTE_STRENGTH * distance(uv, vec2(0.5));
    color.rgb *= DARKEN * vignette;

    fragColor = clamp(color, 0.0, 1.0);
}
