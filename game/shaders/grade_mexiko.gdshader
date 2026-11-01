shader_type canvas_item;
// "Hollywood-Mexiko-Licht": der gelb-orange Farbfilter, mit dem Filme Wuesten und Mexiko zeigen.
// Gelbe Mitten und Lichter, braun-orange Schatten, etwas weniger Saeure, hoher Kontrast, Dunst am Horizont, warme Vignette
// und ein ganz leichtes Flimmern der heissen Luft. Liegt als Vollbild-Schicht unter dem HUD.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform vec3 tint = vec3(1.05, 0.96, 0.78);          // Multiplikation: Blau raus, Gelb rein
uniform vec3 shadow_tint = vec3(0.05, 0.02, 0.0);   // Schatten werden braun-orange
uniform float saturation : hint_range(0.0, 2.0) = 0.80;
uniform float contrast : hint_range(0.5, 1.8) = 1.08;
uniform float haze : hint_range(0.0, 1.0) = 0.12;     // heller gelber Dunst nach oben (Horizont)
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float shimmer : hint_range(0.0, 0.01) = 0.0006;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 70.0 + TIME * 2.2) * shimmer * (1.0 - uv.y * 0.6);
	vec3 c = texture(screen_tex, uv).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c += shadow_tint * (1.0 - smoothstep(0.0, 0.55, l));       // dunkle Bereiche in Braun-Orange
	c *= tint;
	c += vec3(0.95, 0.72, 0.30) * haze * smoothstep(0.55, 0.0, SCREEN_UV.y) * 0.5;
	float hl = smoothstep(0.62, 1.0, l);
	c += vec3(0.05, 0.03, 0.0) * hl;                            // Lichter gluehen gelb
	float v = smoothstep(0.30, 0.95, distance(SCREEN_UV, vec2(0.5)) * 1.3);
	c = mix(c, c * vec3(0.78, 0.45, 0.2), vignette * v);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
