shader_type canvas_item;

uniform float elapsed = 0.0;
uniform float phase = 0.0;
uniform vec4 dust_color : source_color = vec4(0.52, 0.39, 0.32, 1.0);

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(cell), hash2(cell + vec2(1.0, 0.0)), f.x),
		mix(hash2(cell + vec2(0.0, 1.0)), hash2(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * vec2(5.5, 3.2);
	vec2 drift = vec2(elapsed * 0.55 + phase, -elapsed * 0.38);
	float large = noise2(p + drift);
	float detail = noise2(p * 2.2 + drift * 1.6 + 17.0);
	float turbulence = large * 0.72 + detail * 0.28;
	float envelope = 1.0 - smoothstep(0.25, 1.0, length((UV - vec2(0.5, 0.55)) * vec2(2.0, 1.7)));
	float density = mix(0.56, 1.0, smoothstep(0.25, 0.7, turbulence));
	COLOR = vec4(dust_color.rgb * mix(0.72, 1.3, turbulence), dust_color.a * envelope * density);
}
