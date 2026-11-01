shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Schiff auf dem Wasser: zur Kamera gedrehter Sprite, dessen unterer Rand ins Wasser eintaucht. Die unteren Prozent des Bildes werden
// zur Wasserfarbe hin ausgeblendet, davor liegt eine leicht wogende, helle Wasserlinie mit Schaumkranz (Schiff schwimmt statt zu schweben).
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 water_color : source_color = vec4(0.07, 0.30, 0.52, 1.0);
uniform float sink : hint_range(0.0, 0.5) = 0.075;      // Anteil der Bildhoehe unter der Wasserlinie

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
	vec4 t = texture(tex, vuv);
	float from_bottom = 1.0 - vuv.y;                       // 0 = Kiel
	float wob = sin(vuv.x * 38.0 + TIME * 2.2) * 0.012 + sin(vuv.x * 17.0 - TIME * 1.3) * 0.008;
	float line = sink + wob;                               // Wasserlinie
	// unterhalb der Linie: ins Wasser tauchen (durchsichtig, dunkler, Wasserfarbe)
	float under = 1.0 - smoothstep(line - 0.05, line + 0.01, from_bottom);
	vec3 col = mix(t.rgb, water_color.rgb, under * 0.75);
	float a = t.a * (1.0 - under * 0.92);
	// helle Wasserlinie direkt an der Kante des Rumpfes
	float foam = smoothstep(line - 0.02, line, from_bottom) * (1.0 - smoothstep(line, line + 0.035, from_bottom));
	col = mix(col, vec3(0.95, 0.98, 1.0), foam * 0.8 * step(0.05, t.a));
	ALBEDO = col;
	ALPHA = a;
}
