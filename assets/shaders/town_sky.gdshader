shader_type sky;
// D19b: the town's sky. A day gradient, the sun as a disc with a warm halo,
// drifting value-noise clouds, stars after dark and a pale moon. daylight.gd
// drives every uniform each frame; the weather machine sets the cloud cover.

uniform vec3 top_color : source_color = vec3(0.29, 0.46, 0.74);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.79, 0.86);
uniform vec3 ground_horizon : source_color = vec3(0.70, 0.76, 0.80);
uniform vec3 ground_bottom : source_color = vec3(0.46, 0.52, 0.42);
uniform float stars : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.35;
uniform float cloud_dark : hint_range(0.0, 1.0) = 0.0;
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform float gold : hint_range(0.0, 1.0) = 0.0;
uniform float moon_disc : hint_range(0.0, 1.0) = 0.0;
uniform float wind = 1.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 443.8975);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			   mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 4; k++) {
		s += a * vnoise(p);
		p = p * 2.13 + vec2(17.3, 9.1);
		a *= 0.5;
	}
	return s;
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;
	vec3 col;
	if (h >= 0.0) {
		col = mix(horizon_color, top_color, clamp(pow(h, 0.62), 0.0, 1.0));
	} else {
		col = mix(ground_horizon, ground_bottom, clamp(pow(-h, 0.5), 0.0, 1.0));
	}
	// clouds: a flat layer overhead, projected and drifting with the wind
	float cl = 0.0;
	if (h > 0.02) {
		vec2 uv = dir.xz / (h + 0.18) * 0.65;
		uv += vec2(TIME * 0.006, TIME * 0.0023) * wind;
		float n = fbm(uv);
		float edge = 1.0 - cloud_cover;
		cl = smoothstep(edge - 0.18, edge + 0.22, n);
		cl *= smoothstep(0.02, 0.14, h);
		vec3 lit = mix(vec3(1.02, 1.0, 0.98), vec3(1.0, 0.76, 0.56), gold);
		lit = mix(lit, vec3(0.09, 0.10, 0.15), night);
		vec3 base = mix(vec3(0.74, 0.77, 0.83), vec3(0.42, 0.44, 0.50), cloud_dark);
		base = mix(base, vec3(0.05, 0.06, 0.09), night);
		float thick = smoothstep(0.3, 0.9, n);
		vec3 ccol = mix(lit, base, clamp(thick * (0.55 + cloud_dark * 0.45), 0.0, 1.0));
		col = mix(col, ccol, cl * (0.85 + cloud_dark * 0.15));
	}
	// the sun (or the moon) along LIGHT0: a disc and a soft halo, dimmed by cloud
	if (LIGHT0_ENABLED && h > -0.08) {
		float d = distance(dir, LIGHT0_DIRECTION);
		float disc_r = mix(0.016, 0.028, moon_disc);
		float disc = 1.0 - smoothstep(disc_r, disc_r + 0.008, d);
		float halo = exp(-d * d * mix(26.0, 60.0, night));
		vec3 sun_col = mix(vec3(1.0, 0.98, 0.92), vec3(1.0, 0.62, 0.30), gold);
		vec3 lamp = mix(sun_col, moon_disc * vec3(0.86, 0.90, 1.0) + (1.0 - moon_disc) * sun_col, moon_disc);
		float through = 1.0 - cl * 0.92;
		col += lamp * disc * mix(6.0, 1.4, moon_disc) * through;
		col += lamp * halo * mix(0.5, 0.12, night) * (1.0 - cloud_cover * 0.6);
	}
	// stars where the night sky shows through
	if (stars > 0.01 && h > 0.02) {
		vec2 sp = dir.xz / (h + 0.35) * 160.0;
		vec2 cell = floor(sp);
		float r = hash12(cell);
		if (r > 0.994) {
			vec2 c = fract(sp) - 0.5;
			float s = 1.0 - smoothstep(0.0, 0.30, length(c));
			float tw = 0.7 + 0.3 * sin(TIME * (1.5 + r * 60.0) + r * 40.0);
			col += vec3(0.9, 0.93, 1.0) * s * tw * stars * (1.0 - cl)
				 * smoothstep(0.02, 0.2, h) * ((r - 0.994) * 160.0 + 0.25);
		}
	}
	COLOR = col;
}
