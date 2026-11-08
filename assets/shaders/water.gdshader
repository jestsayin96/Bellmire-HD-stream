shader_type spatial;
render_mode cull_disabled;
// River surface: two scrolling noise normals and a fresnel, so the water
// moves and reflects the sky instead of reading as a flat ribbon.
uniform vec3 deep = vec3(0.03, 0.10, 0.12);
uniform vec3 shallow = vec3(0.08, 0.20, 0.21);
uniform float speed = 0.06;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), f.x),
               mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}
vec2 grad(vec2 p) {
    float e = 0.15;
    return vec2(vnoise(p + vec2(e,0)) - vnoise(p - vec2(e,0)),
                vnoise(p + vec2(0,e)) - vnoise(p - vec2(0,e)));
}
void fragment() {
    vec2 p = wpos.xz;
    vec2 g = grad(p * 0.35 + vec2(TIME * speed, TIME * speed * 0.4)) * 0.9
           + grad(p * 0.9 - vec2(TIME * speed * 0.7, 0.0)) * 0.5;
    NORMAL_MAP = normalize(vec3(g * 0.5 + 0.5, 1.0));
    float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    ALBEDO = mix(deep, shallow, 0.35 + 0.3 * vnoise(p * 0.08));
    ROUGHNESS = 0.03;
    METALLIC = 0.0;
    SPECULAR = 0.8;
    ALPHA = mix(0.82, 0.97, fres);
}
