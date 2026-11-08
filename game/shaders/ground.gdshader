shader_type spatial;
render_mode specular_disabled;

// Boden: Gras, Waldboden, Fels, Pfad und Sand/Schlamm am Ufer, alles prozedural.
// Vertexfarbe = Gewichte (R Gras, G Waldboden, B Fels, A Pfad).
uniform float water_level = -0.08;
uniform vec4 map_rect = vec4(-0.5, -0.5, 11.5, 9.5);
uniform float grid_strength : hint_range(0.0, 1.0) = 0.2;
uniform sampler2D swamp_mask : filter_linear, repeat_disable;   // Sumpf: eine Texel je Kachel (1 = Sumpf), weich gefiltert
uniform float swamp_on : hint_range(0.0, 1.0) = 0.0;
uniform float snowland : hint_range(0.0, 1.0) = 0.0;   // Biom Schnee: Gras wird Schnee, Waldboden harter Firn
uniform float swamp : hint_range(0.0, 1.0) = 0.0;      // Biom Sumpf: Gras wird mooriges Olivgruen, Waldboden dunkler Schlamm
uniform float desert : hint_range(0.0, 1.0) = 0.0;     // Biom Wueste: Gras und Waldboden werden zu Sand
uniform float volcano : hint_range(0.0, 1.0) = 0.0;
uniform float lava_flow : hint_range(0.0, 1.0) = 0.0;
uniform float throne_hall : hint_range(0.0, 1.0) = 0.0;   // Biom Thronsaal: Basis-Boden mit goldenen Fugen, violettem Leuchten und rotem Teppich
uniform vec4 carpet_rect = vec4(-99.0, -99.0, -98.0, -98.0);
uniform float base_floor : hint_range(0.0, 1.0) = 0.0;   // Biom Basis: Metallplatten wie in einer Schurkenbasis

varying vec3 wpos;
varying vec3 wnrm;
varying vec4 wts;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wts = COLOR;
}

void fragment() {
	vec2 p = wpos.xz;
	float large = fbm(p * 0.9);
	float mid = fbm(p * 3.5 + 3.1);
	float fine = hash21(floor(p * 40.0));
	float blades = vnoise(p * vec2(55.0, 9.0));

	vec3 grass = mix(vec3(0.20, 0.40, 0.12), vec3(0.45, 0.64, 0.20), smoothstep(0.25, 0.75, large * 0.65 + mid * 0.35));
	grass = mix(grass, vec3(0.62, 0.63, 0.28), smoothstep(0.62, 0.85, fbm(p * 0.35 + 9.0)) * 0.5);
	grass *= (0.9 + 0.2 * fine) * (0.93 + 0.14 * blades);
	vec3 forest = mix(vec3(0.12, 0.25, 0.09), vec3(0.30, 0.26, 0.12), mid) * (0.9 + 0.2 * fine);
	vec3 dirt = mix(vec3(0.42, 0.31, 0.18), vec3(0.55, 0.43, 0.27), mid) * (0.9 + 0.2 * fine);
	float strata = vnoise(vec2(p.x * 2.0 + p.y * 1.3, wpos.y * 14.0));
	vec3 rock = mix(vec3(0.36, 0.34, 0.32), vec3(0.58, 0.55, 0.50), mid * 0.6 + strata * 0.4) * (0.9 + 0.2 * fine);
	vec3 sand = mix(vec3(0.62, 0.55, 0.37), vec3(0.72, 0.65, 0.46), mid) * (0.92 + 0.16 * fine);

	vec3 dune = mix(vec3(0.80, 0.66, 0.42), vec3(0.91, 0.78, 0.52), smoothstep(0.25, 0.75, large * 0.7 + mid * 0.3));
	dune *= (0.94 + 0.12 * fine) * (0.96 + 0.08 * sin(p.x * 5.0 + p.y * 2.2 + large * 7.0));
	grass = mix(grass, vec3(0.42, 0.58, 0.22) * (0.9 + 0.25 * mid), swamp);
	forest = mix(forest, mix(vec3(0.06, 0.05, 0.03), vec3(0.14, 0.10, 0.05), mid) * (0.9 + 0.2 * fine), swamp);
	vec3 snowc = mix(vec3(0.80, 0.86, 0.95), vec3(0.96, 0.98, 1.0), smoothstep(0.25, 0.75, large * 0.65 + mid * 0.35));
	snowc *= (0.95 + 0.07 * fine) * (0.97 + 0.04 * sin(p.x * 3.0 + p.y * 1.6 + large * 6.0));
	grass = mix(grass, snowc, snowland);
	forest = mix(forest, mix(vec3(0.62, 0.70, 0.82), vec3(0.78, 0.84, 0.92), mid) * (0.94 + 0.1 * fine), snowland);
	grass = mix(grass, dune, desert);
	forest = mix(forest, dune * vec3(0.84, 0.72, 0.62), desert);

	float slope = 1.0 - clamp(wnrm.y, 0.0, 1.0);
	float w_rock = clamp(wts.b + smoothstep(0.28, 0.5, slope), 0.0, 1.0);

	vec3 col = grass;
	col = mix(col, forest, clamp(wts.g, 0.0, 1.0));
	col = mix(col, dirt, clamp(wts.a, 0.0, 1.0) * smoothstep(0.15, 0.55, mid + 0.25));
	col = mix(col, rock, w_rock);

	float snow = smoothstep(0.85, 1.1, wpos.y + (fbm(p * 2.0) - 0.5) * 0.25) * (1.0 - smoothstep(0.35, 0.55, slope)) * smoothstep(0.2, 0.5, wts.b);
	col = mix(col, vec3(0.93, 0.95, 1.0), snow);

	// Sumpffelder: weicher, ausgefranster Uebergang vom Gras zum Schlamm (Maske zwischen den Kacheln gefiltert, Raender durch Rauschen verformt)
	if (swamp_on > 0.5) {
		vec2 muv = (wpos.xz - map_rect.xy) / (map_rect.zw - map_rect.xy);
		float m = texture(swamp_mask, clamp(muv, vec2(0.0), vec2(1.0))).r;
		vec2 outside = max(max(-muv, muv - 1.0), vec2(0.0)) * (map_rect.zw - map_rect.xy);
		m *= 1.0 - smoothstep(0.0, 1.2, length(outside));
		float edge = m + (fbm(p * 2.4 + 5.0) - 0.5) * 0.55 + (mid - 0.5) * 0.25;
		float mud_w = smoothstep(0.18, 0.5, edge);
		vec3 mud = mix(vec3(0.06, 0.05, 0.02), vec3(0.14, 0.11, 0.05), mid) * (0.88 + 0.24 * fine);
		mud = mix(mud, vec3(0.16, 0.22, 0.08), smoothstep(0.55, 0.8, fbm(p * 5.0 + 2.0)) * 0.6);      // Algen und Moos
		col = mix(col, mud, mud_w);
	}

	// Ufer: Sand am Wasserrand, darunter dunkler Schlamm
	float shore = smoothstep(water_level + 0.12, water_level + 0.005, wpos.y);
	col = mix(col, sand, shore);
	col = mix(col, vec3(0.20, 0.30, 0.30), smoothstep(water_level, water_level - 0.4, wpos.y));
	vec3 ash = mix(vec3(0.16, 0.13, 0.13), vec3(0.37, 0.29, 0.26), large * 0.55 + mid * 0.45);
	ash *= 0.88 + 0.24 * fine;
	float crust = smoothstep(0.48, 0.74, fbm(p * 2.8 + 14.0));
	ash = mix(ash, vec3(0.11, 0.09, 0.09) * (0.85 + mid * 0.3), crust * 0.6);
	col = mix(col, ash, volcano);
	float crack = 1.0 - smoothstep(0.012, 0.04, abs(sin(p.x * 2.0 + p.y * 1.3 + fbm(p * 0.8) * 5.0)));
	float ember = crack * smoothstep(0.62, 0.72, fbm(p * 0.55 + 31.0)) * volcano;
	// Ein erkalteter Lavastrom durchzieht das Feld; er veraendert keine Spielregeln.
	float flow_x = 3.2 + 0.45 * p.y + sin(p.y * 0.58) * 0.8;
	float flow_dist = abs(p.x - flow_x + (fbm(p * 0.7) - 0.4) * 0.75);
	float flow = (1.0 - smoothstep(1.0, 1.6, flow_dist)) * lava_flow;
	vec3 cooled = mix(vec3(0.19, 0.19, 0.20), vec3(0.34, 0.31, 0.30), mid);
	float bands = 0.5 + 0.5 * sin(flow_dist * 8.0 + p.y * 1.4 + fbm(p * 1.6) * 8.0);
	cooled *= 0.8 + bands * 0.35;
	col = mix(col, cooled, flow * 0.85);
	ember *= 1.0 - flow * 0.65;
	col = mix(col, vec3(0.65, 0.13, 0.025), ember * 0.65);

	// Biom Basis: eine Metallplatte je Kachel (Fugen, Nieten, gebuerstet), einige Fugen leuchten cyan, rote Warnstreifen am Spielfeldrand,
	// ausserhalb und an Steigungen dunklere Wandpaneele
	vec2 cell = floor(p + 0.5);
	vec2 q = fract(p + 0.5);
	vec2 eq = min(q, 1.0 - q);
	float seam = 1.0 - smoothstep(0.018, 0.045, min(eq.x, eq.y));
	vec3 metal = mix(vec3(0.19, 0.22, 0.27), vec3(0.30, 0.33, 0.39), hash21(cell) * 0.6 + mid * 0.4);
	metal *= 0.93 + 0.08 * vnoise(vec2(p.x * 70.0, p.y * 3.0));
	vec2 rq = abs(q - 0.5);
	float rivet = 1.0 - smoothstep(0.022, 0.034, length(rq - vec2(0.41)));
	metal += vec3(0.16) * rivet;
	metal = mix(metal, vec3(0.06, 0.07, 0.09), seam);
	float glow_seam = seam * step(0.72, hash21(cell + 7.3)) * (0.75 + 0.25 * sin(TIME * 1.6 + hash21(cell) * 6.0));
	float inside_b = step(map_rect.x, p.x) * step(map_rect.y, p.y) * step(p.x, map_rect.z) * step(p.y, map_rect.w);
	float edge_d = min(min(p.x - map_rect.x, map_rect.z - p.x), min(p.y - map_rect.y, map_rect.w - p.y));
	float warn = inside_b * (1.0 - smoothstep(0.16, 0.2, edge_d)) * step(0.5, fract((p.x + p.y) * 2.2));
	metal = mix(metal, vec3(0.55, 0.08, 0.06), warn * 0.85);
	vec3 wallc = mix(vec3(0.10, 0.12, 0.16), vec3(0.18, 0.21, 0.26), step(0.5, fract(wpos.y * 1.6)));
	wallc = mix(wallc, vec3(0.05, 0.06, 0.08), 1.0 - smoothstep(0.02, 0.05, abs(fract(wpos.y * 1.6) - 0.5)));
	// Thronsaal: Fugen in dunklem Gold, roter Samtteppich mit Goldborte (Kartenfeld "carpet")
	metal = mix(metal, vec3(0.42, 0.32, 0.12), seam * throne_hall * 0.7);
	float in_carpet = step(carpet_rect.x, p.x) * step(carpet_rect.y, p.y) * step(p.x, carpet_rect.z) * step(p.y, carpet_rect.w);
	float c_edge = min(min(p.x - carpet_rect.x, carpet_rect.z - p.x), min(p.y - carpet_rect.y, carpet_rect.w - p.y));
	vec3 velvet = mix(vec3(0.36, 0.04, 0.06), vec3(0.5, 0.07, 0.09), vnoise(p * 9.0) * 0.6 + mid * 0.4);
	velvet = mix(velvet, vec3(0.78, 0.6, 0.22), (1.0 - smoothstep(0.07, 0.1, c_edge)) * step(0.025, c_edge));
	metal = mix(metal, velvet, in_carpet * throne_hall);
	metal = mix(metal, wallc, clamp(w_rock + (1.0 - inside_b) * 0.6, 0.0, 1.0));
	col = mix(col, metal, base_floor);

	// Spielfeld: dezentes Raster, Umland leicht abgedunkelt
	float inside = step(map_rect.x, p.x) * step(map_rect.y, p.y) * step(p.x, map_rect.z) * step(p.y, map_rect.w);
	vec2 f = fract(p + 0.5);
	vec2 e = min(f, 1.0 - f);
	float line = 1.0 - smoothstep(0.0, 0.03, min(e.x, e.y));
	col *= 1.0 - grid_strength * line * inside * (1.0 - snow);
	col *= 1.0 - 0.1 * (1.0 - inside);

	ALBEDO = col;
	EMISSION = vec3(1.0, 0.17, 0.015) * ember * 0.55 + mix(vec3(0.1, 0.75, 1.0), vec3(0.75, 0.3, 1.0), throne_hall) * glow_seam * inside_b * base_floor * (0.9 - 0.4 * throne_hall);
	ROUGHNESS = 1.0;
}
