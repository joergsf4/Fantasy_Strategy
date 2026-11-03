class_name Settings
extends RefCounted
## Grafikoptionen (Pause-Menue, Reiter "Grafik"): Werte als Index in OPTIONS[i].values, gespeichert in user://settings.cfg und beim Start angewendet.
## Gilt fuer den Compatibility-Renderer: Anzeige, V-Sync, Bildrate, Renderaufloesung, Kantenglaettung, Schatten, Leuchteffekt, Tiefenunschaerfe, Partikel.

const PATH := "user://settings.cfg"
const OPTIONS := [
	{"key": "window", "label": "Anzeige", "values": ["Fenster", "Vollbild"], "default": 1},
	{"key": "vsync", "label": "V-Sync", "values": ["Aus", "An"], "default": 1},
	{"key": "fps", "label": "Bildrate", "values": ["30", "60", "120", "Unbegrenzt"], "default": 3},
	{"key": "scale", "label": "Renderauflösung", "values": ["50 %", "75 %", "100 %"], "default": 2},
	{"key": "aa", "label": "Kantenglättung", "values": ["Aus", "FXAA", "MSAA 2x", "MSAA 4x"], "default": 0},
	{"key": "shadows", "label": "Schatten", "values": ["Aus", "Niedrig", "Mittel", "Hoch"], "default": 3},
	{"key": "glow", "label": "Leuchteffekt", "values": ["Aus", "An"], "default": 1},
	{"key": "tilt", "label": "Tiefenunschärfe", "values": ["Aus", "An"], "default": 1},
	{"key": "particles", "label": "Partikel und Regen", "values": ["Wenig", "Normal", "Viel"], "default": 1},
]
## Voreinstellungen: Werte fuer scale, aa, shadows, glow, tilt, particles (Anzeige, V-Sync und Bildrate bleiben).
const PRESETS := {
	"Niedrig": {"scale": 0, "aa": 0, "shadows": 1, "glow": 0, "tilt": 0, "particles": 0},
	"Mittel": {"scale": 1, "aa": 1, "shadows": 2, "glow": 1, "tilt": 1, "particles": 1},
	"Hoch": {"scale": 2, "aa": 3, "shadows": 3, "glow": 1, "tilt": 1, "particles": 2},
}
const SHADOW_SIZE := [0, 1024, 2048, 4096]
const FPS := [30, 60, 120, 0]
const SCALE := [0.5, 0.75, 1.0]
const PARTICLES := [0.4, 1.0, 1.6]

static var values: Dictionary = {}


static func _ensure() -> void:
	if not values.is_empty():
		return
	for o: Dictionary in OPTIONS:
		values[o["key"]] = int(o["default"])


static func get_value(key: String) -> int:
	_ensure()
	return int(values[key])


static func set_value(key: String, v: int) -> void:
	_ensure()
	for o: Dictionary in OPTIONS:
		if o["key"] == key:
			values[key] = clampi(v, 0, (o["values"] as Array).size() - 1)
			return


## Naechster Wert dieser Option (springt am Ende zum Anfang).
static func cycle(key: String) -> void:
	for o: Dictionary in OPTIONS:
		if o["key"] == key:
			set_value(key, (get_value(key) + 1) % (o["values"] as Array).size())
			return


static func value_text(key: String) -> String:
	for o: Dictionary in OPTIONS:
		if o["key"] == key:
			return (o["values"] as Array)[get_value(key)]
	return ""


static func apply_preset(name: String) -> void:
	for k: String in PRESETS[name]:
		set_value(k, PRESETS[name][k])


## Name der Voreinstellung, die den Werten entspricht ("Eigene", wenn keine passt).
static func preset_name() -> String:
	for n: String in PRESETS:
		var same := true
		for k: String in PRESETS[n]:
			if get_value(k) != int(PRESETS[n][k]):
				same = false
		if same:
			return n
	return "Eigene"


static func cycle_preset() -> void:
	var names: Array = PRESETS.keys()
	var cur := preset_name()
	apply_preset(names[(names.find(cur) + 1) % names.size()] if cur != "Eigene" else names[0])


static func load_file() -> void:
	_ensure()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for o: Dictionary in OPTIONS:
		set_value(o["key"], int(cf.get_value("grafik", o["key"], o["default"])))


static func save_file() -> void:
	_ensure()
	var cf := ConfigFile.new()
	for o: Dictionary in OPTIONS:
		cf.set_value("grafik", o["key"], values[o["key"]])
	cf.save(PATH)


## Einstellungen auf Fenster und Renderer anwenden (Kampfszenen lesen shadows, glow, tilt und particles beim Aufbau selbst).
static func apply(vp: Viewport = null) -> void:
	_ensure()
	if DisplayServer.get_name() == "headless":
		return
	PauseHost.set_fullscreen(get_value("window") == 1)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if get_value("vsync") == 1 else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS[get_value("fps")]
	var v: Viewport = vp if vp != null else (Engine.get_main_loop() as SceneTree).root
	v.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	v.scaling_3d_scale = SCALE[get_value("scale")]
	var aa := get_value("aa")
	v.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	v.msaa_3d = Viewport.MSAA_2X if aa == 2 else (Viewport.MSAA_4X if aa == 3 else Viewport.MSAA_DISABLED)
	var sz: int = SHADOW_SIZE[get_value("shadows")]
	if sz > 0:
		RenderingServer.directional_shadow_atlas_set_size(sz, true)


static func shadows_on() -> bool:
	return get_value("shadows") > 0


static func glow_on() -> bool:
	return get_value("glow") == 1


static func tilt_on() -> bool:
	return get_value("tilt") == 1


static func particle_factor() -> float:
	return PARTICLES[get_value("particles")]
