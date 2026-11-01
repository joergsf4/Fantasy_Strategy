shader_type canvas_item;
// Polarlicht: drei wogende Vorhaenge mit hellem Saum unten und senkrechten Strahlen nach oben, dazu Sternenhimmel.
// Farben und Staerke einstellbar; "energy" laesst das Licht pulsieren (Takt der Musik).

uniform vec4 col_a : source_color = vec4(0.15, 1.0, 0.55, 1.0);
uniform vec4 col_b : source_color = vec4(0.15, 0.7, 1.0, 1.0);
uniform vec4 col_c : source_color = vec4(0.85, 0.3, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.05;
uniform float energy : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	vec3 col = mix(vec3(0.01, 0.02, 0.07), vec3(0.07, 0.03, 0.17), uv.y);
	vec2 sp = uv * vec2(180.0, 100.0);
	float h = hash(floor(sp));
	col += step(0.994, h) * (0.55 + 0.45 * sin(t * 3.0 + h * 40.0)) * 0.9;
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float x = uv.x * (2.2 + fi * 0.8) + t * (0.09 + 0.04 * fi) + fi * 3.1;
		float wave = fbm(vec2(x, t * 0.14 + fi * 5.0));
		float base = 0.62 - 0.12 * fi + 0.2 * (wave - 0.5) + 0.05 * sin(uv.x * 6.0 + t * 0.9 + fi * 2.0);
		float up = base - uv.y;                       // oben ist positiv
		float curtain = smoothstep(-0.015, 0.02, up) * exp(-up * (4.2 + fi));
		float rays = 0.55 + 0.45 * fbm(vec2(uv.x * 38.0 + fi * 7.0, up * 2.5 - t * 0.35));
		vec3 c = mix(col_a.rgb, col_b.rgb, clamp(up * 3.0, 0.0, 1.0));
		c = mix(c, col_c.rgb, clamp(up * 2.4 - 0.5 + fi * 0.18, 0.0, 1.0));
		col += c * curtain * rays * intensity * (0.55 + 0.7 * energy);
	}
	col *= 1.0 - 0.45 * smoothstep(0.35, 0.95, distance(uv, vec2(0.5)));
	COLOR = vec4(vec3(1.0) - exp(-col * 1.5), 1.0);       // weiche Abblendung statt Ueberbelichtung
}
