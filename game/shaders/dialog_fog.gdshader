shader_type canvas_item;
// Blauer Nebel unter den Gespraechsbildern (Dialogue): verdeckt die unterschiedlich hohen Schnittkanten der Portraets.
// Mystisch wabernd: die Nebelgrenze ist verwirbelt (Zungen greifen nach oben), Schwaden verschlingen sich langsam
// (Domain Warping), helle Lichtschleier ziehen hindurch, das Ganze atmet leicht.

uniform vec4 fog_color : source_color = vec4(0.10, 0.22, 0.55, 1.0);
uniform vec4 mist_color : source_color = vec4(0.36, 0.58, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.62, 0.80, 1.0, 1.0);
uniform float top = 0.0;        // ab hier (UV.y) beginnt der Nebel
uniform float solid = 0.58;     // ab hier (UV.y) ist er fast deckend
uniform float max_alpha = 0.97;
uniform float speed = 0.06;
uniform float swirl = 0.55;     // wie weit die Schwaden nach oben greifen

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = rot * p * 2.02;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	vec2 p = vec2(uv.x * 3.2, uv.y * 1.6);
	// Domain Warping: das Rauschfeld verbiegt sich selbst, die Schwaden ringeln sich
	vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, -t * 0.8)));
	vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7 + t * 1.3, 9.2)), fbm(p + 3.0 * q + vec2(8.3, 2.8 - t)));
	float n = fbm(p + 2.6 * r);
	// verwirbelte Grenze: Zungen greifen nach oben, Luecken reissen nach unten auf
	float edge = uv.y + (n - 0.5) * swirl + (r.x - 0.5) * swirl * 0.5;
	float breath = 0.94 + 0.06 * sin(TIME * 0.7);
	float a = smoothstep(top, solid, edge) * max_alpha * breath;
	a = max(a, smoothstep(0.82, 1.0, uv.y) * max_alpha);      // ganz unten immer dicht
	// frei schwebende Schwaden ueber der Nebelgrenze (heben und senken sich mit der Verwirbelung)
	float wisp = smoothstep(0.52, 0.78, n) * smoothstep(0.0, 0.25, uv.y) * (1.0 - smoothstep(0.35, 0.7, uv.y));
	a = max(a, wisp * 0.55 * breath);
	// Farbe: dunkler Grund, hellere Schwaden, feine Lichtschleier an den dichten Stellen der Verwirbelung
	vec3 col = mix(fog_color.rgb, mist_color.rgb, smoothstep(0.35, 0.85, n));
	float veil = smoothstep(0.62, 0.9, length(r) * 0.75) * (1.0 - smoothstep(0.55, 0.95, uv.y));
	col = mix(col, glow_color.rgb, veil * 0.55);
	COLOR = vec4(col, a);
}
