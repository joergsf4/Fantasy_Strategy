shader_type spatial;
render_mode blend_mix, cull_disabled, specular_schlick_ggx;

// Wasser: Vertexfarbe R = Wassertiefe in Kacheln (<= 0 = kein Wasser).
varying vec3 wpos;

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
	for (int i = 0; i < 3; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float depth = COLOR.r;
	vec2 p = wpos.xz;
	float t = TIME;
	float w1 = fbm(p * 2.5 + vec2(t * 0.06, t * 0.04));
	float w2 = fbm(p * 5.0 - vec2(t * 0.05, -t * 0.07));
	float rip = w1 * 0.55 + w2 * 0.45;

	vec3 shallow = vec3(0.28, 0.62, 0.64);
	vec3 deep = vec3(0.07, 0.25, 0.42);
	vec3 col = mix(shallow, deep, smoothstep(0.03, 0.4, depth));
	col += vec3(0.14, 0.18, 0.20) * smoothstep(0.58, 0.72, rip);

	// Schaumkante am Ufer
	float wob = (rip - 0.5) * 0.05 + sin(t * 1.4 + p.x * 3.0 + p.y * 2.0) * 0.008;
	float foam = (1.0 - smoothstep(0.0, 0.05, depth + wob)) * step(0.0, depth);
	col = mix(col, vec3(0.95, 0.98, 1.0), foam * 0.8);

	float a = smoothstep(0.0, 0.04, depth) * 0.45 + smoothstep(0.02, 0.35, depth) * 0.45;
	ALBEDO = col;
	ALPHA = clamp(max(a, foam * 0.85), 0.0, 0.93);
	ROUGHNESS = 0.18;
	SPECULAR = 0.6;
}
