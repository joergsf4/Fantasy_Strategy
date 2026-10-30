shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Effekt-Sprite: immer zur Kamera gedreht, mit eigenem Roll (Drehung um die Blickachse).
// fx.gd erzeugt daraus eine additive Variante (blend_mix -> blend_add).
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha = 1.0;
uniform float glow = 1.0;
uniform float roll = 0.0;

varying vec4 vcol;

void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = normalize(INV_VIEW_MATRIX[1].xyz);
	float c = cos(roll);
	float s = sin(roll);
	vec3 r2 = right * c + up * s;
	vec3 u2 = -right * s + up * c;
	vec3 world = center + r2 * VERTEX.x * sx + u2 * VERTEX.y * sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	vcol = COLOR;
}

void fragment() {
	vec4 t = texture(tex, UV);
	ALBEDO = t.rgb * tint.rgb * vcol.rgb * glow;
	ALPHA = t.a * tint.a * vcol.a * alpha;
}
