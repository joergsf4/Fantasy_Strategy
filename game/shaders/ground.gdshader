shader_type spatial;
render_mode specular_disabled;

// Boden: Gras, Waldboden, Fels, Pfad und Sand/Schlamm am Ufer, alles prozedural.
// Vertexfarbe = Gewichte (R Gras, G Waldboden, B Fels, A Pfad).
uniform float water_level = -0.08;
uniform vec4 map_rect = vec4(-0.5, -0.5, 11.5, 9.5);
uniform float grid_strength : hint_range(0.0, 1.0) = 0.2;

varying vec3 wpos;
varying vec3 wnrm;
varying vec4 wts;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wts = COLOR;
}

void fragment() {
	vec2 p = wpos.xz;
	float large = fbm(p * 0.9);
	float mid = fbm(p * 3.5 + 3.1);
	float fine = hash21(floor(p * 40.0));
	float blades = vnoise(p * vec2(55.0, 9.0));

	vec3 grass = mix(vec3(0.20, 0.40, 0.12), vec3(0.45, 0.64, 0.20), smoothstep(0.25, 0.75, large * 0.65 + mid * 0.35));
	grass = mix(grass, vec3(0.62, 0.63, 0.28), smoothstep(0.62, 0.85, fbm(p * 0.35 + 9.0)) * 0.5);
	grass *= (0.9 + 0.2 * fine) * (0.93 + 0.14 * blades);
	vec3 forest = mix(vec3(0.12, 0.25, 0.09), vec3(0.30, 0.26, 0.12), mid) * (0.9 + 0.2 * fine);
	vec3 dirt = mix(vec3(0.42, 0.31, 0.18), vec3(0.55, 0.43, 0.27), mid) * (0.9 + 0.2 * fine);
	float strata = vnoise(vec2(p.x * 2.0 + p.y * 1.3, wpos.y * 14.0));
	vec3 rock = mix(vec3(0.36, 0.34, 0.32), vec3(0.58, 0.55, 0.50), mid * 0.6 + strata * 0.4) * (0.9 + 0.2 * fine);
	vec3 sand = mix(vec3(0.62, 0.55, 0.37), vec3(0.72, 0.65, 0.46), mid) * (0.92 + 0.16 * fine);

	float slope = 1.0 - clamp(wnrm.y, 0.0, 1.0);
	float w_rock = clamp(wts.b + smoothstep(0.28, 0.5, slope), 0.0, 1.0);

	vec3 col = grass;
	col = mix(col, forest, clamp(wts.g, 0.0, 1.0));
	col = mix(col, dirt, clamp(wts.a, 0.0, 1.0) * smoothstep(0.15, 0.55, mid + 0.25));
	col = mix(col, rock, w_rock);

	float snow = smoothstep(0.85, 1.1, wpos.y + (fbm(p * 2.0) - 0.5) * 0.25) * (1.0 - smoothstep(0.35, 0.55, slope)) * smoothstep(0.2, 0.5, wts.b);
	col = mix(col, vec3(0.93, 0.95, 1.0), snow);

	// Ufer: Sand am Wasserrand, darunter dunkler Schlamm
	float shore = smoothstep(water_level + 0.12, water_level + 0.005, wpos.y);
	col = mix(col, sand, shore);
	col = mix(col, vec3(0.20, 0.30, 0.30), smoothstep(water_level, water_level - 0.4, wpos.y));

	// Spielfeld: dezentes Raster, Umland leicht abgedunkelt
	float inside = step(map_rect.x, p.x) * step(map_rect.y, p.y) * step(p.x, map_rect.z) * step(p.y, map_rect.w);
	vec2 f = fract(p + 0.5);
	vec2 e = min(f, 1.0 - f);
	float line = 1.0 - smoothstep(0.0, 0.03, min(e.x, e.y));
	col *= 1.0 - grid_strength * line * inside * (1.0 - snow);
	col *= 1.0 - 0.1 * (1.0 - inside);

	ALBEDO = col;
	ROUGHNESS = 1.0;
}
