shader_type spatial;
render_mode cull_disabled;
// Lava: two layers of drifting noise, a cooling crust that cracks open to
// bright melt, and emission so it lights its own room.
uniform vec3 hot = vec3(1.0, 0.55, 0.08);
uniform vec3 core = vec3(1.0, 0.92, 0.55);
uniform vec3 crust = vec3(0.10, 0.04, 0.03);
uniform float flow = 0.06;
varying vec3 wpos;
void vertex() {
    wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    VERTEX.y += sin(wpos.x * 0.9 + TIME * 0.7) * 0.03 + cos(wpos.z * 1.1 + TIME * 0.5) * 0.03;
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), f.x), mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
float fbm(vec2 p) { float a = 0.5, s = 0.0; for (int i = 0; i < 4; i++) { s += a * vn(p); p *= 2.03; a *= 0.5; } return s; }
void fragment() {
    vec2 p = wpos.xz * 0.45;
    float n1 = fbm(p + vec2(TIME * flow, TIME * flow * 0.6));
    float n2 = fbm(p * 1.7 - vec2(TIME * flow * 0.8, -TIME * flow * 0.4));
    float heat = smoothstep(0.38, 0.72, n1 * 0.6 + n2 * 0.5);
    float cracks = 1.0 - smoothstep(0.0, 0.06, abs(n2 - 0.5));
    heat = max(heat, cracks * 0.9);
    float pulse = 0.85 + 0.15 * sin(TIME * 1.3 + n1 * 6.0);
    vec3 melt = mix(hot, core, smoothstep(0.7, 1.0, heat));
    ALBEDO = mix(crust, melt * 0.6, heat);
    EMISSION = melt * heat * 3.2 * pulse;
    ROUGHNESS = mix(0.95, 0.35, heat);
}
