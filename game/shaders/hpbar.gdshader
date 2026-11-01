shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled, blend_mix;

// Lebensbalken ueber dem Kopf: dunkler Rahmen in Teamfarbe, Fuellung nach Lebensanteil (gruen, gelb, rot), immer zur Kamera gedreht.
uniform float ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 team_col : source_color = vec4(0.2, 0.5, 1.0, 1.0);

varying vec2 vuv;

void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = normalize(INV_VIEW_MATRIX[1].xyz);
	vec3 world = center + right * VERTEX.x * sx + up * VERTEX.y * sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	vuv = UV;
}

void fragment() {
	vec2 uv = vuv;
	float edge = 0.12;
	vec2 inner = vec2(0.045, 0.2);
	bool in_frame = uv.x > inner.x && uv.x < 1.0 - inner.x && uv.y > inner.y && uv.y < 1.0 - inner.y;
	vec3 col = team_col.rgb * 0.9;
	if (in_frame) {
		float fx = (uv.x - inner.x) / (1.0 - 2.0 * inner.x);
		vec3 fill = ratio > 0.6 ? vec3(0.32, 0.82, 0.34) : (ratio > 0.3 ? vec3(0.95, 0.78, 0.2) : vec3(0.92, 0.25, 0.2));
		float tick = step(0.985, fract(fx * 4.0 + 0.0005)) * 0.12;     // kleine Teilstriche (Viertel)
		col = fx <= ratio ? fill * (1.0 + tick + (1.0 - uv.y) * 0.15) : vec3(0.08, 0.07, 0.1);
	}
	ALBEDO = col;
	ALPHA = 1.0;
}
