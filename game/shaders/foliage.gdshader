shader_type spatial;
render_mode specular_disabled;

// Baeume, Buesche, Felsen: Vertexfarbe * Instanzfarbe, dazu koerniges Blattwerk.
varying vec3 wp;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	VERTEX.x += sin(TIME * 1.1 + wp.x * 1.7 + wp.z) * 0.012 * h;
}

void fragment() {
	float g = hash21(floor(wp.xz * 26.0 + wp.y * 26.0));
	ALBEDO = COLOR.rgb * (0.88 + 0.24 * g);
	ROUGHNESS = 1.0;
}
