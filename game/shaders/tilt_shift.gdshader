shader_type canvas_item;

// Tilt-Shift: scharfes Band in der Bildmitte, nach oben/unten zunehmend unscharf.
// Dazu etwas Saturation und Vignette fuer den "Miniatur"-Look.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float focus_y : hint_range(0.0, 1.0) = 0.58;
uniform float focus_width : hint_range(0.0, 0.5) = 0.12;
uniform float blur_max = 3.4;
uniform float saturation = 1.2;
uniform float contrast = 1.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 uv = SCREEN_UV;
	float d = max(abs(uv.y - focus_y) - focus_width, 0.0);
	float b = clamp(d / 0.5, 0.0, 1.0);
	b = b * b * (3.0 - 2.0 * b);
	float lod = b * blur_max;

	vec2 px = SCREEN_PIXEL_SIZE * (0.6 + lod * 1.6);
	vec3 c = textureLod(screen_tex, uv, lod).rgb * 2.0;
	float w = 2.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		vec2 o = vec2(cos(a), sin(a)) * px * lod * 1.6;
		c += textureLod(screen_tex, uv + o, lod).rgb;
		w += 1.0;
	}
	c /= w;

	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	float v = smoothstep(0.3, 0.95, distance(uv, vec2(0.5)) * 1.25);
	c *= 1.0 - vignette * v;
	COLOR = vec4(c, 1.0);
}
