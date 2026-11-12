// L28a: the dungeon kit's surface. KayKit Dungeon Remastered paints every piece from one
// 8x4 swatch atlas with a single semi-gloss material (roughness 0.45, no normals), so
// stone, wood and gold all read as the same plastic. This keeps the atlas colour and adds:
//  - per-swatch roughness / metalness / which detail set (pbr_map, 8x4, nearest), so the
//    gold swatch is metal, wood is matte, stone is rough;
//  - world-space (triplanar) normal + roughness detail from the CC0 Quaternius Medieval
//    Village MegaKit textures (plaster grain for stone, wood grain) - the atlas has no UV room for it;
//  - a slow world-space albedo variation so tiles stop repeating (vary);
//  - theme wetness on up-facing surfaces (a flooded gallery's floor shines).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D pbr_map : filter_nearest, repeat_enable;      // r rough, g metal, b detail (0 none, .5 stone, 1 wood)
uniform sampler2D stone_n : filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_r : filter_linear_mipmap, repeat_enable;  // roughness in .g (ORM)
uniform sampler2D wood_n : filter_linear_mipmap, repeat_enable;
uniform sampler2D wood_r : filter_linear_mipmap, repeat_enable;   // roughness in .r
uniform sampler2D vary_tex : filter_linear_mipmap, repeat_enable;
uniform float stone_scale = 0.5;      // repeats per metre
uniform float wood_scale = 0.6;
uniform float normal_strength = 0.6;
uniform float rough_mult = 1.0;
uniform float vary = 0.18;
uniform float wet = 0.0;

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 unpack_n(vec4 t) {
	vec2 xy = t.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

// UDN triplanar blend (world-space normal out)
vec3 tri_normal(sampler2D tex, vec3 p, vec3 n, vec3 bw) {
	vec3 tx = unpack_n(texture(tex, p.zy));
	vec3 ty = unpack_n(texture(tex, p.xz));
	vec3 tz = unpack_n(texture(tex, p.xy));
	tx = vec3(tx.xy + n.zy, n.x);
	ty = vec3(ty.xy + n.xz, n.y);
	tz = vec3(tz.xy + n.xy, n.z);
	return normalize(tx.zyx * bw.x + ty.xzy * bw.y + tz.xyz * bw.z);
}

vec4 tri(sampler2D tex, vec3 p, vec3 bw) {
	return texture(tex, p.zy) * bw.x + texture(tex, p.xz) * bw.y + texture(tex, p.xy) * bw.z;
}

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	vec2 cell = floor(clamp(UV, vec2(0.0), vec2(0.9999)) * vec2(8.0, 4.0));
	vec3 pm = texture(pbr_map, (cell + 0.5) / vec2(8.0, 4.0)).rgb;
	vec3 n = normalize(w_nrm);
	vec3 bw = pow(abs(n), vec3(4.0));
	bw /= max(dot(bw, vec3(1.0)), 0.0001);
	// both detail sets are sampled every time (a branch would break the mip derivatives)
	vec3 sp = w_pos * stone_scale;
	vec3 wp = w_pos * wood_scale;
	vec3 sn = tri_normal(stone_n, sp, n, bw);
	vec3 wn = tri_normal(wood_n, wp, n, bw);
	float sr = tri(stone_r, sp, bw).g;
	float wr = tri(wood_r, wp, bw).r;
	float is_wood = step(0.75, pm.b);
	float has_d = step(0.25, pm.b);
	vec3 dn = mix(sn, wn, is_wood);
	float dr = mix(sr, wr, is_wood);
	vec3 nw = normalize(mix(n, dn, normal_strength * has_d));
	float v = tri(vary_tex, w_pos * 0.045, bw).r;
	float up = smoothstep(0.6, 0.9, n.y) * wet;
	vec3 col = a.rgb * tint.rgb * mix(1.0, 0.82 + 0.36 * v, vary);
	col *= 1.0 - 0.35 * up;
	float rough = clamp(pm.r * rough_mult + (dr - 0.5) * 0.4 * has_d, 0.04, 1.0);
	ROUGHNESS = mix(rough, 0.12, up);
	METALLIC = pm.g;
	ALBEDO = col;
	SPECULAR = 0.5;
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
