shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
// Landschafts-Sprite (Baum, Busch, Fels): zeigt wie die Figuren immer zur Kamera (volles Billboard, Fuss am Boden),
// scharfe Pixelkanten per Alpha-Schwelle, die Krone wiegt sich leicht im Wind. Farbe je Instanz (MultiMesh) = Tonung.

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway : hint_range(0.0, 0.2) = 0.045;
uniform float brightness : hint_range(0.5, 1.5) = 0.97;

varying vec3 tint;

void vertex() {
	tint = COLOR.rgb;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.3 + MODEL_MATRIX[3].x * 2.7 + MODEL_MATRIX[3].z * 1.9) * sway * top * top;
}

void fragment() {
	vec4 c = texture(tex, UV);
	ALBEDO = c.rgb * tint * brightness;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
