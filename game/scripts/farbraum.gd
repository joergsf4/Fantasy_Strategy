class_name Farbraum
extends RefCounted
## Ausgleich zwischen den Renderern: Alle Farben und Lichtstimmungen sind fuer den Compatibility-Renderer (OpenGL) abgestimmt.
## Forward+ und Mobile (Metal auf dem Mac) rechnen anders:
## - Farben in den eigenen Shadern: siehe shaders/farbraum.gdshaderinc (LIN), Vertexfarben: vertex_color_is_srgb.
## - Sonne mit Schatten: OpenGL zeichnet sie in einem eigenen Durchgang und addiert ihn auf das fertige sRGB-Bild
##   (Umgebungslicht und Sonne werden getrennt umgerechnet und dann addiert). Das macht besonnte Flaechen deutlich heller,
##   als die Lichtwerte sagen. Metal rechnet linear und addiert vor der Umrechnung: match_sun() hebt die Sonne so weit an,
##   dass flacher Boden gleich hell wird. Gemessen und nachgerechnet in einer Testszene (Abweichung unter 1 %).

const GAMMA := 2.2
const SKY_AMBIENT := 2.7      # Umgebungslicht aus dem Himmel: Faktor auf die mittlere Himmelshelligkeit (gemessen, Mobile)
const MAX_BOOST := 4.0


static func is_compat() -> bool:
	return RenderingServer.get_current_rendering_method() == "gl_compatibility"


static func _lum(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


## Helligkeit des Umgebungslichts (linear, Luminanz), wie es auf eine waagerechte Flaeche faellt.
static func ambient_lum(env: Environment) -> float:
	if env == null:
		return 0.3
	if env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR:
		return env.ambient_light_energy * _lum(env.ambient_light_color)
	if env.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED:
		return 0.0
	var sk := env.sky.sky_material as ProceduralSkyMaterial if env.sky != null else null
	if sk == null:
		return env.ambient_light_energy * 0.5
	return env.ambient_light_energy * SKY_AMBIENT * 0.5 * (_lum(sk.sky_top_color) + _lum(sk.sky_horizon_color)) * sk.energy_multiplier


## Unter Metal: Sonne mit Schatten so verstaerken, dass sie wie unter OpenGL wirkt (unter OpenGL nichts tun).
## Nach allen Lichtvoreinstellungen aufrufen; Tweens auf light_energy sollen den Wert danach lesen.
static func match_sun(sun: DirectionalLight3D, env: Environment) -> void:
	if is_compat() or sun == null or not sun.shadow_enabled or sun.has_meta("farbraum"):
		return
	sun.set_meta("farbraum", true)
	var a := ambient_lum(env)
	var ndl := maxf((sun.global_transform if sun.is_inside_tree() else sun.transform).basis.z.y, 0.05)
	var s := sun.light_energy * _lum(sun.light_color) * ndl
	if s <= 0.0001:
		return
	var s2 := pow(pow(a, 1.0 / GAMMA) + pow(s, 1.0 / GAMMA), GAMMA) - a
	sun.light_energy *= clampf(s2 / s, 1.0, MAX_BOOST)
