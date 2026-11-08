shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha, shadows_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float elapsed = 0.0;
uniform float phase = 0.0;
uniform float strength = 1.0;
uniform vec2 red_green_threshold = vec2(0.08, 0.24);
uniform vec2 red_blue_threshold = vec2(0.08, 0.30);
uniform vec2 brightness_threshold = vec2(0.12, 0.30);
uniform vec4 tint : source_color = vec4(1.0);

void vertex() {
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 up = normalize(INV_VIEW_MATRIX[1].xyz);
	vec3 world = center
		+ right * VERTEX.x * length(MODEL_MATRIX[0].xyz)
		+ up * VERTEX.y * length(MODEL_MATRIX[1].xyz);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

void fragment() {
	vec4 original = texture(tex, UV);
	float fire = smoothstep(red_green_threshold.x, red_green_threshold.y, original.r - original.g)
		* smoothstep(red_blue_threshold.x, red_blue_threshold.y, original.r - original.b)
		* smoothstep(brightness_threshold.x, brightness_threshold.y, original.r);
	float pulse = sin(elapsed * 2.4 + phase + UV.y * 22.0 + UV.x * 9.0)
		* 0.65 + sin(elapsed * 3.7 + phase - UV.y * 37.0 + UV.x * 19.0) * 0.35;
	vec3 cycled = original.rgb * (vec3(1.0) + vec3(0.12, 0.38, 0.16) * pulse * strength);
	ALBEDO = mix(original.rgb, cycled, fire) * tint.rgb;
	ALPHA = original.a * tint.a;
}
