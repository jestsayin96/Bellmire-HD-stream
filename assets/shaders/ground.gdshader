shader_type spatial;
// Valley ground: trodden dirt inside the town, grass outside it and along
// the river banks. Blend is driven by world position so it needs no UVs.
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_nrm : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D grass_nrm : hint_normal, repeat_enable, filter_linear_mipmap;
uniform vec3 grass_tint = vec3(0.50, 0.92, 0.34);
uniform float dirt_scale = 0.14;
uniform float grass_scale = 0.16;
// the town is wide, not round - an ellipse fits its footprint
uniform vec2 town_r = vec2(172.0, 104.0);
uniform float town_fade = 0.22;
// HD: where feet go (red = trodden), painted by town.gd from streets and plots
uniform sampler2D town_mask : filter_linear, repeat_disable;
uniform float mask_half = 200.0;
// D18c: the river surface height, so the ground dips into a wet muddy shore
uniform float water_y = -0.9;
varying vec3 wpos;
varying vec3 wnrm;
// the valley is ringed by mountains: steep ground is bare rock, high ground snow
uniform float rock_slope_lo = 0.30;
uniform float rock_slope_hi = 0.48;
uniform float snow_lo = 95.0;
uniform float snow_hi = 125.0;
// the wild-magic scar: scorched glassy ground with veins of light
uniform vec3 scar_c = vec3(0.0, -9999.0, 0.0);
uniform float scar_r = 30.0;
void vertex() {
    wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
               mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
void fragment() {
    vec2 uvd = wpos.xz * dirt_scale;
    vec2 uvg = wpos.xz * grass_scale;
    float r = length(wpos.xz / town_r);
    float n = vnoise(wpos.xz * 0.05) * 0.6 + vnoise(wpos.xz * 0.21) * 0.4;
    float g = smoothstep(1.0, 1.0 + town_fade, r + (n - 0.5) * 0.25);
    vec2 muv = wpos.xz / (mask_half * 2.0) + 0.5;
    if (muv.x > 0.0 && muv.x < 1.0 && muv.y > 0.0 && muv.y < 1.0) {
        float trod = texture(town_mask, muv).r;
        // ragged edges, not ruled lines
        trod = smoothstep(0.25, 0.75, trod + (n - 0.5) * 0.35);
        g = max(g, 1.0 - trod);
    }
    vec3 dc = texture(dirt_tex, uvd).rgb * vec3(0.72, 0.66, 0.52);
    // D45: grass read as a flat olive/tan wash at pane + aerial distance. Fix:
    // (1) a coarser second sample adds detail that survives mipping far off;
    // (2) macro + patch mottling are GREEN-dominant (G highest), no warm
    //     desaturation, so open fields vary in green instead of washing to tan.
    vec3 gtex = texture(grass_tex, uvg).rgb;
    vec3 gtexC = texture(grass_tex, uvg * 0.34).rgb;
    vec3 gc = mix(gtex, gtexC, 0.45) * grass_tint;
    float macro = vnoise(wpos.xz * 0.008) * 0.5 + vnoise(wpos.xz * 0.023) * 0.5;
    float patch = vnoise(wpos.xz * 0.055 + 3.3);
    gc *= mix(vec3(0.62, 0.74, 0.52), vec3(0.92, 1.06, 0.78), macro);
    gc *= mix(0.84, 1.12, patch);
    vec3 col = mix(dc, gc, g);
    float slope = 1.0 - clamp(wnrm.y, 0.0, 1.0);
    float rk = smoothstep(rock_slope_lo, rock_slope_hi, slope + (n - 0.5) * 0.12);
    vec3 rockc = texture(dirt_tex, wpos.xz * 0.05 + wpos.y * 0.03).rgb;
    rockc = vec3(dot(rockc, vec3(0.33))) * vec3(0.78, 0.76, 0.74) + vec3(0.06);
    col = mix(col, rockc, rk);
    float sn = smoothstep(snow_lo, snow_hi, wpos.y + (n - 0.5) * 14.0) * (1.0 - rk * 0.55);
    col = mix(col, vec3(0.90, 0.92, 0.95), sn);
    // D18c: a damp, muddy shore where the valley ground dips to the waterline,
    // so the bank reads as wet earth sliding under the river instead of a hard
    // grass/water seam. Driven by world height only - no UVs, no bank distance.
    float wet = smoothstep(water_y + 0.55, water_y - 0.2, wpos.y + (n - 0.5) * 0.3);
    vec3 mudc = mix(dc, vec3(0.26, 0.21, 0.15), 0.55);
    col = mix(col, mudc, wet);
    float rough = mix(0.92, 0.38, wet);
    float sd = length(wpos.xz - scar_c.xz);
    float smk = 1.0 - smoothstep(scar_r * 0.55, scar_r * 1.25, sd + (n - 0.5) * 12.0);
    vec3 scorch = vec3(0.09, 0.06, 0.11) * (0.6 + 0.8 * vnoise(wpos.xz * 0.35));
    col = mix(col, scorch, smk);
    float vein = 1.0 - smoothstep(0.0, 0.012, abs(vnoise(wpos.xz * 0.11) - 0.5));
    float vein2 = 1.0 - smoothstep(0.0, 0.010, abs(vnoise(wpos.xz * 0.23 + 7.0) - 0.5));
    vec3 vc = mix(vec3(0.50, 0.15, 1.0), vec3(0.10, 0.70, 1.0), vnoise(wpos.xz * 0.02 + TIME * 0.05));
    // veins flicker out of step - the scar's magic never runs true
    float flick = 0.55 + 0.45 * sin(TIME * 1.7 + vnoise(wpos.xz * 0.05) * 9.0);
    EMISSION = vc * max(vein, vein2 * 0.7) * smk * 1.3 * flick;
    col = mix(col, vc * 0.35, max(vein, vein2 * 0.7) * smk * 0.6);
    ALBEDO = col;
    NORMAL_MAP = mix(texture(dirt_nrm, uvd).rgb, texture(grass_nrm, uvg).rgb, g);
    ROUGHNESS = rough;
}
