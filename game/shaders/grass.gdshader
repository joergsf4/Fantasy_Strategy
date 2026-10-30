shader_type spatial;
render_mode cull_disabled, specular_disabled;

// Grashalme und Blumen im Wind. Vertexfarbe a: 0 = Halm/Stiel, 1 = Blueten-Kopf (Instanzfarbe)
uniform float wind = 0.035;

void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0) / 0.2;
	VERTEX.x += sin(TIME * 1.7 + o.x * 2.0 + o.z * 1.3) * wind * h;
	VERTEX.z += cos(TIME * 1.3 + o.z * 2.1 + o.x * 0.7) * wind * 0.6 * h;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
