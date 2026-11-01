class_name Battle
extends Node3D
## Rundenkampf auf der 3D-Rasterkarte. Logik laeuft auf Vector2i (Grid), die 3D-Knoten sind nur Darstellung.

signal finished(won: bool)

const PORTRAIT_DIR := "res://assets/portraits/"
const TOKEN_DIR := "res://assets/tokens/"
const COL_MOVE := Color(0.25, 0.55, 1.0, 0.45)
const COL_ATTACK := Color(1.0, 0.25, 0.2, 0.55)
const COL_HEAL := Color(0.3, 1.0, 0.4, 0.55)
const COL_SELF := Color(1.0, 0.9, 0.2, 0.5)
const TEAM_COLOR := {"p": Color(0.2, 0.5, 1.0), "e": Color(0.95, 0.2, 0.2)}

enum State { IDLE, SELECTED, ACTION, TARGETING, BUSY, OVER }

var map_data: Dictionary
var unit_defs: Dictionary
var grid: Grid
var units: Array[Dictionary] = []
var state := State.IDLE
var turn := 1
var sel: Dictionary = {}
var sel_origin := Vector2i.ZERO
var reach: Dictionary = {}
var cam: Camera3D
var _mats: Dictionary = {}
var _tex_cache: Dictionary = {}
var terrain: TerrainView
var _hl_root: Node3D
var _cursor: MeshInstance3D
var _info: TextBox
var _status: Label
var _hint: TextBox
var _end_btn: Button
var _card_rich: RichTextLabel
var _hud_layer: CanvasLayer
var fx: Fx
var _closeup := false             # Aufnahmemodus: keine Balken und Zahlen
var _detail := false              # Alt gedrueckt: alle Lebenszahlen und Statusnamen zeigen
var _hover_unit: Dictionary = {}  # Figur unter dem Mauszeiger
var _clock := 0.0                 # Spielzeit fuer die Meldungs-Warteschlange (laeuft wie die Timer mit Engine.time_scale)
var _popup_next := {}             # Figur -> fruehester Start der naechsten Meldung
var _popup_count := {}            # Figur -> Anzahl bisheriger Meldungen (wechselnde Seite)
var _popup_live := {}             # Figur -> laufende Meldungen [{label, base, n, t0}]
var _banner_label: Label
var _banner_tween: Tween
var popup_scale := 1.0   # Groesse der Schadens- und Statuszahlen (Trailer nutzt kleinere)
var _hud_root: Control
var _menu: PanelContainer
var _card: PanelContainer
var _card_icon: TextureRect
var _card_name: Label
var _card_hp: ProgressBar
var _card_status: Label
var _forecast: TextBox
var _target_kind := ""
var _target_units: Array[Dictionary] = []
var sel_dir := Vector2i.RIGHT
var cam_home := Transform3D.IDENTITY
var _in_stage := false
var abilities: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _cur_ab := ""
var _cur_item := ""
var chests: Array[Dictionary] = []     # {pos, reward, open, node}
var villages: Array[Dictionary] = []   # {pos, reward, visited}
var loot := {"gold": 0, "items": {}, "materials": {}, "equipment": []}   # Beute dieses Kampfes (Gegenstaende gehen direkt in den Rucksack)
var all_units: Array[Dictionary] = []     # alle je gespawnten Figuren (fuer die Statistik, auch gefallene)
var fallen: Array[String] = []         # gefallene Helden (fuer Bonusziele)
var _start_inventory: Dictionary = {}
var _results: Dictionary = {}
var goal: Dictionary = {"type": "rout"}
var _scheduled: Array = []                # zeitversetzte Ereignisse {turn, id}
var kids_stung := 0                     # wie oft Bienen das Waisenhaus erreicht haben
var triggers: Array = []                 # {when, do, fired}
var _notes: Array = []                    # Ereignisse seit der letzten Pruefung: {kind, ...}
var kills_total := 0                      # besiegte Gegner insgesamt
var _actor: Dictionary = {}               # zuletzt handelnde Figur (fuer "$hero" bei Ereignissen ohne eigenen Ausloeser)
var super_music := Callable()            # von main gesetzt: func(on: bool) -> daempft die Kampfmusik waehrend einer Super-Attacke
var secret_runner := Callable()           # async func(secret: Dictionary) -> von main gesetzt, zeigt die Szene einer geheimen Interaktion
var secrets_seen: Array = []              # schon gezeigte Szenen (Party)
var secrets_done: Array = []              # in diesem Kampf ausgeloeste Geheimnisse
var dialogue_runner := Callable()         # async func(lines: Array) -> von main gesetzt, zeigt Dialoge ueber der Karte
var _goal: TextBox
var world: World
const FIRE_DAMAGE := 4
var _flammable: Dictionary = {}          # Waldfelder: dort breitet sich Feuer aus
var _fire_preview: Node3D                # orange Felder: dort faengt es in der naechsten Feuerphase Feuer
var _obj_nodes: Dictionary = {}          # Objekt-ID -> {root, body, rubble, doors, lever}
var _target_objs: Array[Dictionary] = []  # anwaehlbare Weltobjekte beim Zielen
var _landing_ally: Dictionary = {}
var _landing_tiles: Array[Vector2i] = []
var retreated: Array = []           # Gegner, die sich freiwillig zurueckgezogen haben
var fled: Array = []                # in dieser Mission geflohene Gegner (kehren spaeter zurueck)
var nemeses: Array = []             # aus frueheren Missionen entkommene Gegner (Party)
var loadout: Dictionary = {}      # {inventory: {Gegenstand: Anzahl}, equipment: {Held: [Ausruestung]}}
var inventory: Dictionary = {}    # Rucksack der Spielerseite
var _acted := false
var _next_uid := 1
var _away: Array[Dictionary] = []   # verwandelte Einheiten (aus dem Spiel)


func setup(map: Dictionary, defs: Dictionary) -> void:
	map_data = map
	unit_defs = defs


func _ready() -> void:
	abilities = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	rng.randomize()
	inventory = (loadout.get("inventory", {}) as Dictionary).duplicate()
	nemeses = (loadout.get("nemesis", []) as Array).duplicate()
	secrets_seen = (loadout.get("secrets_seen", []) as Array).duplicate()
	_start_inventory = inventory.duplicate()
	for k: String in abilities:
		abilities[k]["id"] = k
	grid = Grid.new(map_data["rows"])
	world = World.new(map_data.get("objects", []))
	grid.blocked = world.blocked()
	terrain = TerrainView.new()
	terrain.biome = map_data.get("biome", "wiese")
	terrain.setup(grid)
	add_child(terrain)
	_build_environment()
	fx = Fx.new()
	add_child(fx)
	fx.setup(self)
	_build_loot()
	_build_objects()
	_build_decor()
	for fy in grid.height:
		for fx_ in grid.width:
			if grid.terrain(Vector2i(fx_, fy)) == "F":
				_flammable[Vector2i(fx_, fy)] = true
	_fire_preview = Node3D.new()
	add_child(_fire_preview)
	_update_fire_preview()
	goal = (map_data.get("goals", [{"type": "rout"}]) as Array)[0]
	if goal.get("type", "rout") == "reach":      # Zielfeld golden markieren, leicht pulsierend
		var gt := Vector2i(goal["tile"][0], goal["tile"][1])
		var gm := MeshInstance3D.new()
		gm.mesh = terrain.tile_mesh(gt, 0.48, 0.07)
		gm.material_override = _mat(Color(1.0, 0.82, 0.25, 0.55), true, true)
		add_child(gm)
		var pulse := gm.create_tween().set_loops()
		pulse.tween_property(gm, "transparency", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(gm, "transparency", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	triggers = (map_data.get("triggers", []) as Array).duplicate(true)
	_hl_root = Node3D.new()
	add_child(_hl_root)
	_cursor = MeshInstance3D.new()
	_cursor.material_override = _mat(Color(1, 1, 1, 0.3), true, true)
	_cursor.visible = false
	add_child(_cursor)
	for e: Dictionary in map_data["players"]:
		_spawn(e["id"], "p", Vector2i(e["pos"][0], e["pos"][1]))
	for e: Dictionary in map_data["enemies"]:
		_spawn(e["id"], "e", Vector2i(e["pos"][0], e["pos"][1]), {"carry": e.get("carry", {}), "guard": e.get("guard", false), "hp": e.get("hp")} if e.has("hp") else {"carry": e.get("carry", {}), "guard": e.get("guard", false)})
	_build_hud()
	_update_status()


# ---------------------------------------------------------------- Darstellung

## Wuestenlicht ("Hollywood-Mexiko"): tiefe, harte, gelb-orange Sonne mit laengeren Schatten, warmes Umgebungslicht und
## ein Farbfilter ueber dem ganzen Bild (unter dem HUD, siehe shaders/grade_mexiko.gdshader).
func _apply_desert_light(env: Environment, sun: DirectionalLight3D) -> void:
	sun.rotation_degrees = Vector3(-34, -50, 0)
	sun.light_color = Color(1.0, 0.86, 0.62)
	sun.light_energy = 0.95
	sun.shadow_opacity = 0.8
	env.ambient_light_color = Color(1.0, 0.84, 0.62)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.42
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var rect := ColorRect.new()
	rect.size = Vector2(1280, 720)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/grade_mexiko.gdshader")
	rect.material = mat
	layer.add_child(rect)


func _mat(c: Color, transparent := false, unshaded := false) -> StandardMaterial3D:
	var key := [c, transparent, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


func _mesh(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func to_world(p: Vector2i) -> Vector3:
	return Vector3(p.x, terrain.tile_height(p), p.y)


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.5, 0.86)
	sky_mat.sky_horizon_color = Color(0.80, 0.87, 0.94)
	sky_mat.ground_horizon_color = Color(0.72, 0.80, 0.74)
	sky_mat.ground_bottom_color = Color(0.45, 0.55, 0.45)
	sky_mat.sun_angle_max = 25.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.fog_enabled = false
	env.fog_light_color = Color(0.78, 0.86, 0.93)
	env.fog_density = 0.005
	env.glow_enabled = true
	env.glow_intensity = 0.2
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.65
	add_child(sun)
	if map_data.get("biome", "") == "wueste" and map_data.get("grade", "mexiko") != "none":
		_apply_desert_light(env, sun)
	var center := Vector3((grid.width - 1) / 2.0, 0, (grid.height - 1) / 2.0)
	cam = Camera3D.new()
	cam.fov = 40
	cam.far = 120.0
	add_child(cam)
	cam.position = center + Vector3(0, 12.6, 9.0)
	cam.look_at(center)
	cam_home = cam.transform


func _portrait_tex(id: String) -> Texture2D:
	if _tex_cache.has(id):
		return _tex_cache[id]
	var path := TOKEN_DIR + id + ".png"
	if not ResourceLoader.exists(path):
		path = PORTRAIT_DIR + id + ".png"  # noch kein Chibi-Token
	var img: Image = (load(path) as Texture2D).get_image()
	var s := 256.0 / maxf(img.get_width(), img.get_height())
	img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[id] = tex
	return tex


func _spawn(id: String, team: String, pos: Vector2i, extra := {}) -> void:
	var d: Dictionary = unit_defs[id]
	var u := {
		"id": id, "name": d["name"], "team": team, "pos": pos,
		"hp": d["hp"], "maxhp": d["hp"], "atk": d["atk"], "def": d["def"], "res": d.get("res", 0),
		"move": d["move"], "range": d["range"], "range_min": d.get("range_min", 1),
		"dmg_type": d.get("dmg_type", "body"), "role": d.get("role", ""), "tags": d.get("tags", []),
		"abilities": d.get("abilities", []), "passives": d.get("passives", []),
		"ranged_mult": d.get("ranged_mult", 1.0), "flying": d.get("flying", false),
		"heal": d.get("heal", 0), "done": false, "status": [], "cd": {}, "dir": Vector2i.RIGHT,
		"uid": str(_next_uid), "charge": 0,
		"weapon": d.get("weapon", "fist"), "body": d.get("body", "flesh"),
		"st": {"dealt": 0, "taken": 0, "healed": 0, "kills": 0, "abs": 0, "bonus": 0},
	}
	all_units.append(u)
	_next_uid += 1
	if extra.has("hp"):
		u["hp"] = int(extra["hp"])
		u["maxhp"] = int(extra["hp"])
	if team == "p":     # Faehigkeiten, die nur diese Mission gewaehrt ("grants": {Held: [Faehigkeit]}), z. B. Breitseite
		for ab_id: String in (map_data.get("grants", {}) as Dictionary).get(id, []):
			(u["abilities"] as Array).append(ab_id)
	u["carry"] = extra.get("carry", {})
	u["guard"] = extra.get("guard", false)    # Wache: bleibt auf dem Posten, bis ein Held nahe kommt
	if team == "p":
		Items.apply_equipment(u, (loadout.get("equipment", {}) as Dictionary).get(id, []))
	var node := Node3D.new()
	node.position = to_world(pos)
	add_child(node)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.33
	ring.bottom_radius = 0.33
	ring.height = 0.05
	u["ring"] = _mesh(ring, TEAM_COLOR[team], Vector3(0, 0.03, 0), node)
	var lift := 0.35 if u["flying"] else 0.0
	var tex := _portrait_tex(d.get("portrait", id))
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = float(d.get("size", 1.35)) / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	# Drehpunkt am Fuss der Figur, damit sie sich beim Billboarding nicht in den Boden dreht
	sp.offset = Vector2(0, tex.get_height() / 2.0)
	sp.position = Vector3(0, 0.08 + lift, 0)
	if d.has("tint"):
		var t: Array = d["tint"]
		sp.modulate = Color(t[0], t[1], t[2])
	node.add_child(sp)
	if not (u["carry"] as Dictionary).is_empty():
		_loot_marker(node, lift)
	# Ueber dem Kopf steht standardmaessig nur ein schmaler Lebensbalken; Zahl und Statusnamen erscheinen bei Auswahl, Hover und Alt.
	# Hoehe in Kamera-Richtung "oben": die Kamera blickt steil von oben, Welt-Hoehen waeren stark gestaucht, die Sprites aber nicht.
	u["bar_h"] = float(d.get("size", 1.35)) + 0.14
	u["lift"] = lift
	var bar := MeshInstance3D.new()
	bar.mesh = _bar_mesh()
	var bmat := ShaderMaterial.new()
	bmat.shader = load("res://shaders/hpbar.gdshader")
	bmat.set_shader_parameter("team_col", TEAM_COLOR[team])
	bmat.render_priority = 4
	bar.material_override = bmat
	bar.scale = Vector3(0.62, 0.1, 1.0)
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(bar)
	u["bar"] = bar
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font = UiTheme.font(UiTheme.F_TITLE)
	lbl.font_size = 40
	lbl.pixel_size = 0.0048
	lbl.outline_size = 14
	lbl.no_depth_test = true
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl.modulate = TEAM_COLOR[team].lerp(Color.WHITE, 0.55)
	lbl.visible = false
	node.add_child(lbl)
	u["node"] = node
	u["sprite"] = sp
	# Blickrichtungspfeil auf dem Ring (die Blickrichtung zaehlt fuer Ruecken-/Flankenangriffe)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.07, 0)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.09
	cone.height = 0.2
	cone.radial_segments = 3
	var arrow := _mesh(cone, TEAM_COLOR[team].lerp(Color.WHITE, 0.55), Vector3(0.43, 0, 0), pivot)
	arrow.rotation_degrees = Vector3(0, 0, -90)
	node.add_child(pivot)
	u["arrow"] = pivot
	_face_step(u, Vector2i(-1 if pos.x > (grid.width - 1) / 2.0 else 1, 0))
	u["label"] = lbl
	units.append(u)
	_refresh_unit(u)


## Blickrichtung (logisch, 4 Richtungen). Das Bild wird nur links/rechts gespiegelt (Portraits zeigen nach rechts).
func _face_step(u: Dictionary, delta: Vector2i) -> void:
	if delta == Vector2i.ZERO:
		return
	u["dir"] = Vector2i(signi(delta.x), signi(delta.y))
	if delta.x != 0:
		(u["sprite"] as Sprite3D).flip_h = delta.x < 0
	(u["arrow"] as Node3D).rotation.y = atan2(-float(u["dir"].y), float(u["dir"].x))


## Blickt auf ein Feld (dominante Achse).
func _turn_towards(u: Dictionary, target: Vector2i) -> void:
	var d: Vector2i = target - u["pos"]
	if absi(d.x) >= absi(d.y):
		_face_step(u, Vector2i(signi(d.x), 0))
	else:
		_face_step(u, Vector2i(0, signi(d.y)))


## Gemeinsamer Lebensbalken-Netz fuer alle Figuren.
var _bar_quad: QuadMesh

func _bar_mesh() -> QuadMesh:
	if _bar_quad == null:
		_bar_quad = QuadMesh.new()
		_bar_quad.size = Vector2.ONE
	return _bar_quad


## Text der Detailanzeige (Auswahl, Hover, Alt): Leben und alle Status mit Restdauer, je Status eine Zeile.
func _label_text(u: Dictionary) -> String:
	var st := Status.label(u)
	return "%d/%d" % [u["hp"], u["maxhp"]] + ("\n" + st.replace(", ", "\n") if st != "" else "")


## Soll die Detailanzeige dieser Figur gerade sichtbar sein?
func _label_shown(u: Dictionary) -> bool:
	var uid: String = u["uid"]
	return not _in_stage and not _closeup and (_detail or uid == sel.get("uid", "") or uid == _hover_unit.get("uid", ""))


func _sync_labels() -> void:
	for u in units:
		var l := u["label"] as Label3D
		l.visible = _label_shown(u)
		if l.visible:
			l.text = _label_text(u)


func _refresh_unit(u: Dictionary) -> void:
	((u["bar"] as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("ratio", clampf(float(u["hp"]) / float(maxi(1, u["maxhp"])), 0.0, 1.0))
	(u["label"] as Label3D).text = _label_text(u)
	(u["label"] as Label3D).visible = _label_shown(u)
	var base := Color.WHITE
	var d: Dictionary = unit_defs[u["id"]]
	if d.has("tint"):
		base = Color(d["tint"][0], d["tint"][1], d["tint"][2])
	var c := base * (Color(0.5, 0.5, 0.55) if u["done"] else Color.WHITE)
	c.a = 0.45 if Status.has(u, "stealth") else 1.0
	(u["sprite"] as Sprite3D).modulate = c
	if fx != null:
		fx.sync_status(u)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	_hud_layer = layer
	add_child(layer)
	var root := Control.new()   # Wurzel fuer das Fantasy-Theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	layer.add_child(root)
	_hud_root = root
	# Rundenband oben links
	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.position = Vector2(8, 6)
	banner.add_theme_stylebox_override("panel", UiTheme.soft_plate())
	root.add_child(banner)
	_status = Label.new()
	_status.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	_status.add_theme_font_size_override("font_size", 17)
	_status.add_theme_color_override("font_color", UiTheme.GOLD)
	_status.add_theme_constant_override("outline_size", 3)
	banner.add_child(_status)
	_hint = TextBox.new(16, false, true)
	_hint.position = Vector2(12, 44)
	root.add_child(_hint)
	_goal = TextBox.new(17, false, true)
	_goal.position = Vector2(330, 8)
	root.add_child(_goal)
	_build_card(root)
	_info = TextBox.new(15, false, true)
	_info.position = Vector2(12, 688)
	root.add_child(_info)
	_forecast = TextBox.new(17, true, true)
	_forecast.position = Vector2(390, 620)
	_forecast.custom_minimum_size = Vector2(500, 0)
	root.add_child(_forecast)
	_end_btn = Button.new()
	_end_btn.text = "Zug beenden"
	_end_btn.position = Vector2(1126, 8)
	_end_btn.custom_minimum_size = Vector2(146, 34)
	_end_btn.add_theme_font_size_override("font_size", 15)
	for st in ["normal", "hover", "pressed", "disabled"]:
		_end_btn.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	_end_btn.focus_mode = Control.FOCUS_NONE
	_end_btn.pressed.connect(_end_player_turn)
	root.add_child(_end_btn)


func _build_card(root: Control) -> void:
	_card = PanelContainer.new()
	_card.position = Vector2(8, 84)
	_card.add_theme_stylebox_override("panel", UiTheme.soft("panel_dark_s.png", Vector4(10, 8, 12, 8), 0.8))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_card.add_child(row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.box("frame_s.png", 12, Vector4(4, 4, 4, 4), 0.9))
	row.add_child(frame)
	_card_icon = TextureRect.new()
	_card_icon.custom_minimum_size = Vector2(46, 54)
	_card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(_card_icon)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(172, 0)
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	_card_name = Label.new()
	_card_name.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	_card_name.add_theme_font_size_override("font_size", 16)
	_card_name.add_theme_color_override("font_color", UiTheme.GOLD)
	col.add_child(_card_name)
	_card_hp = ProgressBar.new()
	_card_hp.custom_minimum_size = Vector2(0, 9)
	_card_hp.show_percentage = false
	col.add_child(_card_hp)
	_card_rich = RichTextLabel.new()
	_card_rich.bbcode_enabled = true
	_card_rich.fit_content = true
	_card_rich.scroll_active = false
	_card_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_rich.add_theme_font_size_override("normal_font_size", 14)
	col.add_child(_card_rich)
	_card_status = Label.new()
	_card_status.add_theme_font_size_override("font_size", 14)
	_card_status.add_theme_color_override("font_color", Color(0.65, 1.0, 0.65))
	col.add_child(_card_status)
	_card.visible = false
	root.add_child(_card)


func _show_card(u: Dictionary) -> void:
	if u.is_empty():
		_card.visible = false
		return
	_card.visible = true
	var id: String = u["id"]
	var d: Dictionary = unit_defs[id]
	var pid: String = d.get("portrait", id)
	var path := TOKEN_DIR + pid + ".png"
	if not ResourceLoader.exists(path):
		path = PORTRAIT_DIR + pid + ".png"
	_card_icon.texture = load(path)
	_card_name.text = "%s%s" % [u["name"], "" if u["team"] == "p" else "  (Gegner)"]
	_card_hp.max_value = u["maxhp"]
	_card_hp.value = u["hp"]
	_card_hp.add_theme_stylebox_override("fill", UiTheme.hp_fill(float(u["hp"]) / float(u["maxhp"])))
	var rng := "%d" % u["range"] if u["range"] == 1 else "%d–%d" % [u["range_min"], u["range"]]
	var g := "[color=#e6c25a]"
	_card_rich.text = "%sLeben[/color] %d/%d   %sBew[/color] %d   %sRei[/color] %s\n%sAngriff[/color] %d   %sVert[/color] %d   %sRes[/color] %d\n%s" % [
		g, u["hp"], u["maxhp"], g, u["move"], g, rng,
		g, Combat.stat(u, "atk"), g, Combat.stat(u, "def"), g, Combat.stat(u, "res"),
		"[color=#9fb8ff]Magie[/color]" if u["dmg_type"] == "magic" else "[color=#ffb49f]Körper[/color]"]
	var gear: Array = []
	for eid: String in u.get("equip", []):
		gear.append(Items.equipment()[eid]["name"])
	_card_status.text = Status.label(u) + ("\n" if Status.label(u) != "" and not gear.is_empty() else "") + (", ".join(gear) if not gear.is_empty() else "")
	_card_status.visible = _card_status.text != ""


func _update_status() -> void:
	_sync_labels()
	_status.text = "Runde %d  –  %s" % [turn, "Deine Phase" if state != State.BUSY else "Gegner / Aktion"]
	_goal.text = Mission.goal_text(goal, _count_team("e"), turn, _capture_info())
	match state:
		State.IDLE:
			_hint.text = "Wähle eine blaue Figur."
		State.SELECTED:
			_hint.text = "Ziel-Feld wählen (blau). Rechtsklick = abbrechen."
		State.ACTION:
			_hint.text = "Aktion wählen. Rechtsklick = Zug zurücknehmen."
		State.TARGETING:
			_hint.text = "Ziel wählen (Vorschau unten). Rechtsklick = zurück zum Menü."
		_:
			_hint.text = ""


## Nur fuer Aufnahmen: HUD aus, Kamera bleibt wie gesetzt.
func _enter_close_view() -> void:
	_hud_layer.visible = false
	_cursor.visible = false
	_closeup = true
	for u in units:
		(u["label"] as Label3D).visible = false
		(u["bar"] as MeshInstance3D).visible = false


## Schaufenster-Modus (Titelbild, Dialoge): keine Bedienung, keine HUD-Anzeigen.
func enter_title_mode() -> void:
	_in_stage = true
	_hud_layer.visible = false
	_cursor.visible = false
	_show_tiles({})
	_close_menu()
	set_process_unhandled_input(false)
	for u in units:
		(u["label"] as Label3D).visible = false
		(u["bar"] as MeshInstance3D).visible = false


## Zurueck ins Spiel: HUD an, Kamera fliegt auf die Standardansicht.
func exit_title_mode() -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "transform", cam_home, 1.2)
	tw.tween_property(cam, "fov", 40.0, 1.2)
	await tw.finished
	_in_stage = false
	_hud_layer.visible = true
	set_process_unhandled_input(true)
	for u in units:
		(u["bar"] as MeshInstance3D).visible = true
	_sync_labels()
	state = State.IDLE
	_update_status()


# ------------------------------------------------------------------ Hilfen

func unit_at(p: Vector2i) -> Dictionary:
	for u in units:
		if u["pos"] == p:
			return u
	return {}


func _team_tiles(team: String) -> Dictionary:
	var d := {}
	for u in units:
		if u["team"] == team:
			d[u["pos"]] = true
	return d


func _show_tiles(tiles: Dictionary) -> void:
	for c in _hl_root.get_children():
		c.queue_free()
	for p: Vector2i in tiles:
		var q := MeshInstance3D.new()
		q.mesh = terrain.tile_mesh(p)
		q.material_override = _mat(tiles[p], true, true)
		_hl_root.add_child(q)


## Kachel unter dem Mauszeiger. Figuren haben Vorrang: der Koerper einer Figur ragt ueber das Feld dahinter,
## ein Klick darauf meint die Figur und nicht das Feld, das sie verdeckt.
func _pick_tile(screen: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for u in units:
		var sp: Sprite3D = u["sprite"]
		if not is_instance_valid(sp) or not sp.visible or sp.texture == null:
			continue
		var foot := (u["node"] as Node3D).position + Vector3(0, 0.08, 0)
		var h := sp.texture.get_height() * sp.pixel_size
		var w := sp.texture.get_width() * sp.pixel_size
		var a := cam.unproject_position(foot)
		var top := cam.unproject_position(foot + Vector3(0, h, 0))
		var half := absf(a.y - top.y) * (w / h) * 0.3     # schmaler als die Bildbreite: Figuren sind meist schlank
		if absf(screen.x - a.x) <= half and screen.y >= top.y and screen.y <= a.y + 8.0:
			var d := cam.global_position.distance_to(foot)
			if d < best_d:
				best_d = d
				best = u["pos"]
	if best != Vector2i(-1, -1):
		return best
	return terrain.pick(cam.project_ray_origin(screen), cam.project_ray_normal(screen))


## Warum kann die gewaehlte Figur ein Feld nicht betreten? (Rueckmeldung statt stillem Abbruch)
func _why_not_reachable(p: Vector2i) -> String:
	if not grid.inside(p):
		return "Außerhalb der Karte."
	var o := unit_at(p)
	if not o.is_empty() and o != sel:
		return "Feld besetzt (%s)." % o["name"]
	if not sel["flying"] and Grid.TERRAIN[grid.terrain(p)]["cost"] < 0:
		return "Wasser kann nicht betreten werden."
	if not sel["flying"] and grid.blocked.has(p):
		return "Ein Hindernis versperrt das Feld."
	var d := Grid.dist(sel_origin, p)
	return "Zu weit entfernt (Bewegung %d)." % sel["move"] if d > sel["move"] else "Nicht erreichbar: Gelände kostet mehr Bewegung, als übrig ist."


## Vorschau eines Angriffs: Schaden, Positionsbonus-Hinweise, Gegenschlag.
## att_pos = Feld, von dem aus angegriffen wird (Standard: aktuelles Feld).
func forecast(att: Dictionary, def: Dictionary, att_pos := Vector2i(-99, -99), mult := 1.0, ignore_def := 0.0) -> Dictionary:
	var pos: Vector2i = att["pos"] if att_pos == Vector2i(-99, -99) else att_pos
	var dist := Grid.dist(pos, def["pos"])
	var pb := Combat.position_bonus(pos, def["pos"], def["dir"], terrain.tile_height(pos), terrain.tile_height(def["pos"]), Status.has(att, "stealth"))
	var flat: int = att["charge"] if (att["passives"] as Array).has("sturmangriff") and mult == 1.0 else 0
	var dmg := Combat.damage(att, def, _cover_for(def, def["pos"]), pb["bonus"], mult * Combat.range_mult(att, dist), ignore_def, flat)
	var counter := -1
	if def["hp"] - dmg > 0 and Combat.can_counter(def, dist):
		var cpb := Combat.position_bonus(def["pos"], pos, att["dir"], terrain.tile_height(def["pos"]), terrain.tile_height(pos))
		counter = Combat.damage(def, att, _cover_for(att, pos), cpb["bonus"], Combat.range_mult(def, dist))
	return {"dmg": dmg, "tags": pb["tags"], "counter": counter, "kill": def["hp"] <= dmg}


## Deckung durch Gelaende (+ Schildwall: +1 neben anderer Infanterie).
func _cover_for(u: Dictionary, pos: Vector2i) -> int:
	var c := grid.def_bonus(pos)
	if (u["passives"] as Array).has("schildwall"):
		for o in units:
			if o != u and o["team"] == u["team"] and (o["passives"] as Array).has("schildwall") and Grid.dist(o["pos"], pos) == 1:
				c += 1
				break
	return c


func damage(att: Dictionary, def: Dictionary) -> int:
	return forecast(att, def)["dmg"]


## Unantastbare Figuren (Robinas Panzer, solange er auf der Gegenseite steht) sind kein Ziel von Angriffen und Faehigkeiten.
## Nach der Uebernahme (oder in spaeteren Missionen als Held) ist Robina ein ganz normales Ziel.
func _hittable(o: Dictionary) -> bool:
	return not ((o["tags"] as Array).has("unantastbar") and o["team"] == "e")


func _attack_targets(u: Dictionary, pos: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in units:
		if o["team"] != u["team"] and _hittable(o) and not Status.has(o, "stealth") and Combat.in_range(u, Grid.dist(pos, o["pos"])):
			out.append(o)
	return out


func _heal_targets(u: Dictionary, pos: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if u["heal"] <= 0:
		return out
	for o in units:
		if o != u and o["team"] == u["team"] and Combat.in_range(u, Grid.dist(pos, o["pos"])) \
				and (o["hp"] < o["maxhp"] or Status.has(o, "poison")):
			out.append(o)
	return out


# --------------------------------------------------------------------- Eingabe

## Alt gedrueckt halten zeigt Lebenszahlen und alle Status (auch waehrend Animationen).
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode in [KEY_ALT, KEY_META] and not event.echo:
		_detail = event.pressed
		_sync_labels()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _detail:
		_detail = false
		_sync_labels()


func _process(delta: float) -> void:
	_clock += delta
	_place_overlays()


## Balken, Detailtext und Symbolreihe stehen ueber dem Kopf, gemessen entlang der Kamera-Hochachse (siehe _spawn).
func _place_overlays() -> void:
	if cam == null:
		return
	var up := cam.global_transform.basis.y.normalized()
	var right := cam.global_transform.basis.x.normalized()
	for u in units:
		if not u.has("bar"):
			continue
		var off := up * float(u["bar_h"]) + Vector3.UP * float(u["lift"])
		(u["bar"] as Node3D).position = off
		(u["label"] as Node3D).position = off + up * 0.5
		var holders: Dictionary = u.get("fx_nodes", {})
		for id: String in holders:
			var h := holders[id] as Node3D
			var ic := h.get_node_or_null("icon") as Node3D if is_instance_valid(h) else null
			if ic != null:
				ic.position = off + up * 0.34 + right * (float(ic.get_meta("slot", 0.0)) * Fx.ICON_STEP)
		var more := u.get("more") as Node3D
		if more != null and is_instance_valid(more):
			more.position = off + up * 0.3 + right * (float(more.get_meta("slot", 0.0)) * Fx.ICON_STEP)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.BUSY or state == State.OVER:
		return
	if event is InputEventMouseMotion:
		_hover(_pick_tile(event.position))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click(_pick_tile(event.position))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel()
	elif event.is_action_pressed("ui_cancel"):
		_cancel()


func _hover(p: Vector2i) -> void:
	_forecast.text = ""
	var hu := unit_at(p) if grid.inside(p) else {}
	if hu.get("uid", "") != _hover_unit.get("uid", ""):
		_hover_unit = hu
		_sync_labels()
	if not grid.inside(p):
		_cursor.visible = false
		_info.text = ""
		_show_card(sel)
		return
	_cursor.visible = true
	_cursor.mesh = terrain.tile_mesh(p, 0.5, 0.045)
	var t: Dictionary = Grid.TERRAIN[grid.terrain(p)]
	_info.text = "%s (Deckung +%d)" % [t["name"], t["def"]]
	var u := unit_at(p)
	if state == State.SELECTED and not reach.has(p) and u.is_empty():
		_info.text += "   –   " + _why_not_reachable(p)
	_show_card(u if not u.is_empty() else sel)
	if state == State.TARGETING and not u.is_empty() and _target_units.has(u):
		_forecast.text = _forecast_text(sel, u)
		if _target_kind == "ability" and (abilities[_cur_ab]["target"] == "ally_center" or abilities[_cur_ab].get("shape", "") == "line"):
			_show_ability_tiles(u["pos"])
	elif state == State.TARGETING and _target_kind == "ability_tile" and _landing_tiles.has(p):
		var ab: Dictionary = abilities[_cur_ab]
		var tt := {sel["pos"]: COL_SELF}
		for q in _landing_tiles:
			tt[q] = Color(1.0, 0.82, 0.25, 0.3)
		for q in _area_tiles(ab, p):
			tt[q] = Color(1.0, 0.6, 0.15, 0.45)
		tt[p] = Color(1.0, 0.6, 0.15, 0.7)
		_show_tiles(tt)
		_forecast.text = "%s\n%s" % [ab["name"], ab["text"]]
	elif state == State.TARGETING and u.is_empty():
		var wo := world.at(p)
		if not wo.is_empty() and _target_objs.has(wo):
			_forecast.text = _object_forecast(wo)


func _forecast_text(att: Dictionary, def: Dictionary) -> String:
	if _target_kind == "item":
		var it: Dictionary = Items.consumables()[_cur_item]
		return "%s auf %s\n%s" % [it["name"], def["name"], it["text"]]
	if _target_kind == "heal":
		var s := "%s heilt %s: +%d HP" % [att["name"], def["name"], mini(att["heal"], def["maxhp"] - def["hp"])]
		return s + ("  (Gegengift)" if Status.has(def, "poison") else "")
	if _target_kind == "ability":
		var ab: Dictionary = abilities[_cur_ab]
		var dm := _first_effect(ab, "damage")
		if ab["target"] == "enemy" and def["team"] == att["team"]:
			return "%s: %s → %s" % [ab["name"], att["name"], def["name"]]      # geheime Interaktion: kein Hinweis
		if ab["target"] == "enemy" and not dm.is_empty():
			var hits: int = dm.get("hits", 1)
			var fc := forecast(att, def, att["pos"], dm["mult"], dm.get("ignore_def", 0.0))
			var total: int = fc["dmg"] * hits
			var s := "%s: %s → %s  %d Schaden%s (HP %d → %d)" % [ab["name"], att["name"], def["name"], total, " (%d×%d)" % [hits, fc["dmg"]] if hits > 1 else "", def["hp"], maxi(0, def["hp"] - total)]
			if not fc["tags"].is_empty():
				s += "\n" + ", ".join(fc["tags"])
			return s + "\n" + ab["text"]
		return "%s\n%s" % [ab["name"], ab["text"]]
	var fc := forecast(att, def)
	var s := "%s → %s:  %d Schaden  (HP %d → %d)" % [att["name"], def["name"], fc["dmg"], def["hp"], maxi(0, def["hp"] - fc["dmg"])]
	if not fc["tags"].is_empty():
		s += "\n" + ", ".join(fc["tags"])
	s += "\nGegenschlag: %s" % ("%d Schaden" % fc["counter"] if fc["counter"] >= 0 else ("tödlich!" if fc["kill"] else "keiner"))
	return s


func _click(p: Vector2i) -> void:
	if not grid.inside(p):
		return
	var u := unit_at(p)
	match state:
		State.IDLE:
			if not u.is_empty() and u["team"] == "p" and not u["done"]:
				_select(u)
		State.SELECTED:
			if not u.is_empty() and u != sel and u["team"] == "p" and not u["done"]:
				_select(u)
			elif reach.has(p) and (u.is_empty() or u == sel):
				_move_player(p)
			else:
				_hint.text = _why_not_reachable(p)   # Auswahl bleibt, Rechtsklick bricht ab
		State.TARGETING:
			if _target_kind == "landing":
				if _landing_tiles.has(p):
					_do_throw_ally(p)
			elif _target_kind == "ability_tile":
				if _landing_tiles.has(p):
					_do_tile_ability(p)
			elif not u.is_empty() and _target_units.has(u):
				if _target_kind == "ability" and (abilities[_cur_ab].get("caps", []) as Array).has("throw_ally") and u["team"] == sel["team"]:
					_begin_landing(u)
				else:
					_act(sel, u)
			else:
				var wo := world.at(p)
				if not wo.is_empty() and _target_objs.has(wo):
					_act_object(sel, wo)


func _cancel() -> void:
	match state:
		State.SELECTED:
			sel = {}
			state = State.IDLE
			_show_tiles({})
			_show_card({})
		State.ACTION:
			if _acted:
				return   # nach einer freien Faehigkeit (Stabsprung) kein Zurueck mehr
			_close_menu()
			sel["pos"] = sel_origin
			(sel["node"] as Node3D).position = to_world(sel_origin)
			_face_step(sel, sel_dir)
			_select(sel)
			return
		State.TARGETING:
			_forecast.text = ""
			_enter_action()
			return
	_update_status()


func _select(u: Dictionary) -> void:
	sel = u
	sel_origin = u["pos"]
	sel_dir = u["dir"]
	_acted = false
	var blocked := _team_tiles("e") if u["team"] == "p" else _team_tiles("p")
	reach = grid.reachable(u["pos"], Combat.move_of(u), u["flying"], blocked)
	var occupied := {}
	for o in units:
		if o != u:
			occupied[o["pos"]] = true
	var tiles := {}
	for p: Vector2i in reach:
		if not occupied.has(p):
			tiles[p] = COL_MOVE
	reach[u["pos"]] = 0   # besetzte Felder bleiben in reach: man darf durch eigene Leute laufen, nur das Ziel muss frei sein
	tiles[u["pos"]] = COL_SELF
	_show_tiles(tiles)
	_show_card(u)
	state = State.SELECTED
	_update_status()


func _move_player(p: Vector2i) -> void:
	state = State.BUSY
	_show_tiles({})
	_update_status()
	await _walk(sel, p)
	await _run_triggers("enter", p, sel)
	_check_end()
	if state == State.OVER:
		return
	_enter_action()


## Aktionsmenue neben der Figur.
func _enter_action(show_abilities := false, show_items := false) -> void:
	state = State.ACTION
	_show_tiles({sel["pos"]: COL_SELF})
	_close_menu()
	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", UiTheme.soft("panel_dark_s.png", Vector4(8, 6, 8, 6), 0.88))
	var box := VBoxContainer.new()
	_menu.add_child(box)
	if show_abilities:
		for id: String in sel["abilities"]:
			var ab: Dictionary = abilities[id]
			var cd: int = sel["cd"].get(id, 0)
			var ok := cd == 0 and (not _ab_targets(sel, id, sel["pos"]).is_empty() or not _obj_targets(sel, id, sel["pos"]).is_empty() or not _ab_tiles(sel, id, sel["pos"]).is_empty())
			var b := _menu_button(box, ab["name"] + (" (%d)" % cd if cd > 0 else ""), ok, func() -> void: _begin_ability(id))
			b.mouse_entered.connect(func() -> void: _info.text = ab["text"])
		_menu_button(box, "Zurück", true, func() -> void: _enter_action())
	elif show_items:
		for id: String in Items.consumables():
			var n: int = inventory.get(id, 0)
			if n <= 0:
				continue
			var it: Dictionary = Items.consumables()[id]
			var ok: bool = not _item_targets(sel, id).is_empty() or (it.get("douse", false) and not _douse_targets(sel).is_empty())
			var bi := _menu_button(box, "%s ×%d" % [it["name"], n], ok, func() -> void: _begin_item(id))
			bi.mouse_entered.connect(func() -> void: _info.text = it["text"])
		_menu_button(box, "Zurück", true, func() -> void: _enter_action())
	else:
		var atk := _attack_targets(sel, sel["pos"])
		_menu_button(box, "Angriff", not atk.is_empty() or not _attack_objs(sel, sel["pos"]).is_empty(), func() -> void: _begin_targeting("attack"))
		if sel["heal"] > 0:
			_menu_button(box, "Heilen", not _heal_targets(sel, sel["pos"]).is_empty(), func() -> void: _begin_targeting("heal"))
		if not (sel["abilities"] as Array).is_empty():
			_menu_button(box, "Fähigkeit", true, func() -> void: _enter_action(true))
		if sel["team"] == "p" and _has_items():
			_menu_button(box, "Gegenstand", true, func() -> void: _enter_action(false, true))
		if sel["team"] == "p" and not _douse_targets(sel).is_empty():
			_menu_button(box, "Feuer löschen", true, func() -> void: _begin_targeting("douse"))
		if sel["team"] == "p":
			var ch := _chest_at(sel["pos"])
			if not ch.is_empty() and not ch["open"]:
				_menu_button(box, "Truhe öffnen", true, func() -> void: _collect(sel, ch, "chest"))
			var so := world.at(sel["pos"])
			if not so.is_empty() and so["type"] == "switch" and so["state"] == "off":
				_menu_button(box, "Schalter umlegen", true, func() -> void: _use_switch(sel, so))
			for ob in world.objects:
				if ob["type"] == "bell" and ob["state"] == "ready" and Grid.dist(sel["pos"], ob["pos"]) == 1:
					_menu_button(box, "Glocke läuten", true, func() -> void: _ring_bell(sel, ob))
			var hs := _hostage_near(sel["pos"])
			if not hs.is_empty():
				var ho := _hostage_option(hs)
				_menu_button(box, ho["text"], ho["enabled"], func() -> void: _free_hostage(sel, hs))
			var vl := _village_at(sel["pos"])
			if not vl.is_empty() and not vl["visited"]:
				_menu_button(box, "Dorf besuchen", true, func() -> void: _collect(sel, vl, "village"))
		_menu_button(box, "Verteidigen", true, func() -> void: _defend(sel))
		_menu_button(box, "Warten (wachsam)", true, func() -> void:
			_close_menu()
			Status.add(sel, "wachsam", 1, {"atk": Combat.WAIT_ATK})
			_refresh_unit(sel)
			_popup(sel, "Wachsam", Color(1.0, 0.9, 0.5))
			_finish_unit(sel))
	_hud_root.add_child(_menu)
	var sp := cam.unproject_position((sel["node"] as Node3D).position + Vector3(0.7, 1.0, 0))
	_menu.position = Vector2(clampf(sp.x, 20.0, 1000.0), clampf(sp.y - 20.0, 70.0, 500.0))
	_update_status()


func _menu_button(box: VBoxContainer, text: String, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 30)
	b.add_theme_font_size_override("font_size", 15)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	box.add_child(b)
	return b


func _close_menu() -> void:
	if _menu != null and is_instance_valid(_menu):
		_menu.queue_free()
	_menu = null


# ------------------------------------------------------------------ Beute

func _build_loot() -> void:
	for c: Dictionary in map_data.get("chests", []):
		var pos := Vector2i(c["pos"][0], c["pos"][1])
		var entry := {"pos": pos, "reward": c["reward"], "open": false, "node": null, "lid": null, "look": c.get("look", "chest")}
		_make_chest(entry)
		chests.append(entry)
	for v: Dictionary in map_data.get("villages", []):
		villages.append({"pos": Vector2i(v["pos"][0], v["pos"][1]), "reward": v["reward"], "visited": false})


func _chest_at(p: Vector2i) -> Dictionary:
	for c in chests:
		if c["pos"] == p:
			return c
	return {}


func _village_at(p: Vector2i) -> Dictionary:
	for v in villages:
		if v["pos"] == p:
			return v
	return {}


## Truhe aus Holz mit Eisenbaendern, Deckel und goldenem Schloss.
func _make_chest(entry: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(entry["pos"])
	add_child(root)
	entry["node"] = root
	entry["lid"] = null
	if entry["look"] == "honey":     # Honigtopf statt Truhe: Sprite, wird beim Einsammeln ausgeblendet
		fx.make_sprite("fx_honigtopf", Vector3(0, 0.3, 0), 0.6, false, Color.WHITE, 0, root)
		return
	entry["closed"] = _object_sprite("fx_truhe", 0.8, root)
	var op := _object_sprite("fx_truhe_offen", 0.85, root)
	op.visible = false
	entry["open_s"] = op


func _unshaded_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true
	m.render_priority = 5
	return m


## Beutesack, der ueber dem Kopf eines Traegers schwebt (immer sichtbar, auch hinter Baeumen).
func _loot_marker(node: Node3D, lift: float) -> void:
	var m := Node3D.new()
	m.name = "LootMarker"
	m.position = Vector3(0.0, 2.2 + lift, 0)
	fx.make_sprite("fx_beutel", Vector3.ZERO, 0.45, false, Color.WHITE, 2, m)
	node.add_child(m)
	var tw := m.create_tween().set_loops()
	tw.tween_property(m, "position:y", m.position.y + 0.08, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "position:y", m.position.y, 0.7).set_trans(Tween.TRANS_SINE)


## Belohnung gutschreiben: Gegenstaende in den Rucksack, Zutaten/Gold/Ausruestung in die Beute.
## Rueckgabe: Textzeilen fuer die Anzeige.
func _grant(reward: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for id: String in reward.get("items", {}):
		var n := int(reward["items"][id])
		inventory[id] = int(inventory.get(id, 0)) + n
		loot["items"][id] = int(loot["items"].get(id, 0)) + n
		lines.append("+%s%s" % [Items.item_name(id), " ×%d" % n if n > 1 else ""])
	for id: String in reward.get("materials", {}):
		var n2 := int(reward["materials"][id])
		loot["materials"][id] = int(loot["materials"].get(id, 0)) + n2
		lines.append("+%s%s" % [Items.item_name(id), " ×%d" % n2 if n2 > 1 else ""])
	for id: String in reward.get("equipment", []):
		(loot["equipment"] as Array).append(id)
		lines.append("+%s" % Items.item_name(id))
	if int(reward.get("gold", 0)) > 0:
		loot["gold"] += int(reward["gold"])
		lines.append("+%d Gold" % int(reward["gold"]))
	return lines


## Truhe oeffnen oder Dorf besuchen: kostet die Aktion der Figur, einmalig.
func _collect(u: Dictionary, entry: Dictionary, kind: String) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	if kind == "chest":
		entry["open"] = true
		if entry.has("closed"):     # Truhe: geschlossener Sprite gegen den offenen tauschen, kurzer Sprung
			(entry["closed"] as Node3D).visible = false
			var os := entry["open_s"] as Node3D
			os.visible = true
			var tw := create_tween()
			tw.tween_property(os, "scale", os.scale * 1.15, 0.12)
			tw.tween_property(os, "scale", os.scale, 0.18)
		else:
			(entry["node"] as Node3D).visible = false
	else:
		entry["visited"] = true
	var lines := _grant(entry["reward"])
	Sfx.event("chest" if kind == "chest" else "village")
	Sfx.event("coin")
	fx.light_flash(fx.chest(u, 0.6), Color(1.0, 0.85, 0.4), 2.0, 3.0, 0.5)
	await _popup(u, "\n".join(lines), Color(1.0, 0.9, 0.5))
	_finish_unit_after(u)


## Besiegte Gegner mit Beute geben sie sofort her; gefallene Helden werden vermerkt.
func _on_death(def: Dictionary) -> void:
	_note("death", {"unit": def, "by": _actor})
	if not _actor.is_empty() and _actor["team"] != def["team"]:
		_actor["st"]["kills"] += 1
	if def["team"] == "e":
		kills_total += 1
		var carry: Dictionary = def.get("carry", {})
		if not carry.is_empty():
			var lines := _grant(carry)
			Sfx.event("coin")
			_popup(def, "\n".join(lines), Color(1.0, 0.9, 0.5))
			def["carry"] = {}
	else:
		fallen.append(def["id"])


## Eine Figur faellt (Leben 0, schon aus `units` entfernt): Gegner mit "flees" fliehen wuetend und kehren spaeter
## zurueck, alle anderen sterben.
func _down(def: Dictionary) -> void:
	_on_death(def)
	if def["team"] == "e" and unit_defs[def["id"]].get("flees", false) and not (map_data.get("no_flee", []) as Array).has(def["id"]):
		await _flee(def)
	else:
		fx.death(def)


## Wuetender Rueckzug: Beute faellt, Dialog (mission "flee": {id: [Zeilen]}), dann rennt die Figur zum naechsten Kartenrand.
func _flee(def: Dictionary, talk := true) -> void:
	fled.append(def["id"])
	var n: Node3D = def["node"]
	fx.flash_unit(def, Color(2.0, 0.5, 0.4), 0.3)
	await _popup(def, "Rückzug!", Color(1.0, 0.5, 0.35))
	Sfx.event("flee")
	var lines: Array = (map_data.get("flee", {}) as Dictionary).get(def["id"], [])
	if lines.is_empty():
		lines = [{"left": "$hero", "right": def["id"], "speaker": def["id"], "right_expr": "wuetend", "text": "Das merke ich mir! Wir sehen uns wieder!"}]
	if talk and dialogue_runner.is_valid():
		var was_visible := _hud_layer.visible
		_hud_layer.visible = false
		await dialogue_runner.call(_hero_lines(lines, _actor))
		_hud_layer.visible = was_visible
	if is_instance_valid(n):
		var p := def["pos"] as Vector2i
		var dirs := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
		var best: Vector2i = dirs[0]
		var best_d := 999
		for d: Vector2i in dirs:
			var dd := p.x if d.x < 0 else (grid.width - 1 - p.x if d.x > 0 else (p.y if d.y < 0 else grid.height - 1 - p.y))
			if dd < best_d:
				best_d = dd
				best = d
		var out := n.position + Vector3(best.x, 0, best.y) * (best_d + 3.0)
		var tw := create_tween()
		tw.tween_property(n, "position", out, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(def["sprite"], "modulate:a", 0.0, 0.9)
		await tw.finished
		n.queue_free()


## Schaden fuer die Statistik: Angreifer teilt aus (falls bekannt), Ziel steckt ein.
func _count(att: Dictionary, def: Dictionary, real: int) -> void:
	if not att.is_empty() and att["team"] != def["team"]:
		att["st"]["dealt"] += real
	def["st"]["taken"] += real


## Statistik der Heldenseite: je Figur Zahlen, dazu Auszeichnungen (nur wenn jemand mehr als 0 geschafft hat).
func stats() -> Dictionary:
	var rows: Array = []
	for u in all_units:
		if u["team"] != "p":
			continue
		var s: Dictionary = u["st"]
		rows.append({"id": u["id"], "name": u["name"], "alive": u["hp"] > 0, "hp": u["hp"], "maxhp": u["maxhp"],
			"dealt": s["dealt"], "taken": s["taken"], "healed": s["healed"], "kills": s["kills"], "abs": s["abs"], "bonus": s["bonus"]})
	var awards: Array = []
	var pick := func(key: String, title: String, text: String) -> void:
		var best: Dictionary = {}
		for r: Dictionary in rows:
			if r[key] > 0 and (best.is_empty() or r[key] > best[key]):
				best = r
		if not best.is_empty():
			awards.append({"title": title, "name": best["name"], "text": text % best[key]})
	pick.call("dealt", "Schlagkräftigster", "%d Schaden ausgeteilt")
	pick.call("taken", "Prügelknabe", "%d Schaden eingesteckt")
	pick.call("healed", "Sanitäter", "%d Leben geheilt")
	pick.call("kills", "Gegnerschreck", "%d Gegner besiegt")
	pick.call("bonus", "Taktiker", "%d Treffer von hinten, der Seite oder oben")
	var close: Dictionary = {}
	for r: Dictionary in rows:
		if r["alive"] and (close.is_empty() or float(r["hp"]) / float(r["maxhp"]) < float(close["hp"]) / float(close["maxhp"])):
			close = r
	if not close.is_empty() and float(close["hp"]) / float(close["maxhp"]) < 0.5:
		awards.append({"title": "Knapp davongekommen", "name": close["name"], "text": "mit %d von %d Leben" % [close["hp"], close["maxhp"]]})
	return {"rows": rows, "awards": awards}


## Ergebnis fuer Belohnungsbildschirm und Party: Rucksack-Rest samt Beute, Zutaten, Gold, Ziele.
func results() -> Dictionary:
	if not _results.is_empty():
		return _results     # nur einmal berechnen, sonst wuerden Belohnungen doppelt gutgeschrieben
	var gained := {"gold": int(loot["gold"]), "items": (loot["items"] as Dictionary).duplicate(),
		"materials": (loot["materials"] as Dictionary).duplicate(), "equipment": (loot["equipment"] as Array).duplicate()}
	var done: Array = []
	for o: Dictionary in map_data.get("objectives", []):
		var ok := false
		match o["id"]:
			"alle_leben":
				ok = fallen.is_empty()
			"schnell":
				ok = turn <= int(o["turns"])
			"haeuser":
				ok = world.houses_lost() == 0
			"praxis":
				ok = world.by_id("praxis")["state"] != "ruin"
			"keine_stiche":
				ok = kids_stung == 0
			"alle_gegner":
				ok = _count_team("e") == 0
			"ueberzeugt":
				ok = retreated.has(o["unit"])
		done.append({"id": o["id"], "text": o["text"], "done": ok, "reward": o.get("reward", {})})
	# Kapitelbelohnung und erfuellte Ziele gutschreiben
	var bonus: Array = [map_data.get("rewards", {})]
	for d: Dictionary in done:
		if d["done"]:
			bonus.append(d["reward"])
	for r: Dictionary in bonus:
		for id: String in r.get("items", {}):
			inventory[id] = int(inventory.get(id, 0)) + int(r["items"][id])
			gained["items"][id] = int(gained["items"].get(id, 0)) + int(r["items"][id])
		for id: String in r.get("materials", {}):
			gained["materials"][id] = int(gained["materials"].get(id, 0)) + int(r["materials"][id])
		for id: String in r.get("equipment", []):
			(gained["equipment"] as Array).append(id)
		gained["gold"] += int(r.get("gold", 0))
	gained["inventory"] = inventory.duplicate()
	gained["objectives"] = done
	gained["turns"] = turn
	gained["fled"] = fled.duplicate()
	gained["secrets_seen"] = secrets_seen.duplicate()
	gained["stats"] = stats()
	_results = gained
	return gained


## Bilanz einer verlorenen Mission: nur die Statistik (keine Beute, keine Belohnungen), fuer den Niederlage-Bildschirm.
func defeat_summary() -> Dictionary:
	return {"defeat": true, "stats": stats(), "turns": turn, "objectives": [], "gold": 0, "items": {}, "materials": {}, "equipment": []}


# ------------------------------------------------------------------ Weltobjekte

## Dekoration ohne Spielwirkung: im Biom Wueste Kakteen auf "F"-Feldern (und vereinzelt auf Sand), dazu die "decor"-Liste der Karte
## ([{sprite, pos, size}], z. B. Palmen an der Oase). Alles Pixel-Sprites.
func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var spots: Array = []     # [Sprite, Feld, Groesse]
	if map_data.get("biome", "") == "wueste":
		for y in grid.height:
			for x in grid.width:
				var p := Vector2i(x, y)
				if grid.blocked.has(p) or world.at(p) != {}:
					continue
				var t := grid.terrain(p)
				if t == "F":
					spots.append(["fx_kaktus", p, 1.0])
				elif t == "G" and rng.randf() < 0.06:
					spots.append(["fx_kaktus", p, 0.6])
	for y in grid.height:        # Burg-Felder (C): Burg-Sprite; Dorf-Felder: Dorfplatz-Sprite
		for x in grid.width:
			if grid.terrain(Vector2i(x, y)) == "C":
				spots.append(["fx_burg", Vector2i(x, y), 1.45])
	for y in grid.height:        # Dorf-Felder: Dorfplatz-Sprite statt Mini-Haeuschen (Wiese oder Wueste)
		for x in grid.width:
			if grid.terrain(Vector2i(x, y)) == "V" and world.at(Vector2i(x, y)).is_empty():
				spots.append(["fx_dorf_wueste" if map_data.get("biome", "") == "wueste" else "fx_dorf", Vector2i(x, y), 1.5])
	for d: Dictionary in map_data.get("decor", []):
		spots.append([d["sprite"], Vector2i(d["pos"][0], d["pos"][1]), float(d.get("size", 1.0))])
	for sp: Array in spots:
		var root := Node3D.new()
		root.position = to_world(sp[1]) + Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.1, 0.1))
		add_child(root)
		_object_sprite(sp[0], sp[2], root)


func _build_objects() -> void:
	for o in world.objects:
		_make_object(o)
		_refresh_object(o, false)


func _make_object(o: Dictionary) -> void:
	if o["type"] == "fire" or o["type"] == "house":
		_make_burnable(o)
		return
	if o["type"] == "hostage":
		_make_hostage(o)
		return
	if o["type"] in ["hive", "hive_p", "bell", "orphanage", "ship", "crate", "teahouse", "tent", "switch"]:
		_make_ch5_object(o)
		return
	var stone := Color(0.52, 0.5, 0.54)
	var dark := Color(0.38, 0.37, 0.42)
	var wood := Color(0.42, 0.26, 0.13)
	var iron := Color(0.3, 0.3, 0.34)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	if o["dir"] == "h":
		root.rotation.y = PI * 0.5
	add_child(root)
	var parts := {"root": root, "body": null, "rubble": null, "doors": [], "lever": null}
	var body := MeshKit.new()
	match o["type"]:
		"wall":
			StoneWall.wall(body, o["pos"])
		"gate":
			StoneWall.gate_pillars(body, o["pos"])
			body.box(Vector3(0, 0.8, 0), Vector3(0.48, 0.14, 0.62), wood)
			for z in [-0.4, 0.4]:   # rote Banner auf den Pfeilern: das Tor faellt auf
				# Banner zeigen zur Kamera: bei waagerechter Mauer (dir "h", Wurzel um 90 Grad gedreht) Masse vertauschen
				var cloth := Vector3(0.03, 0.26, 0.3) if o["dir"] == "h" else Vector3(0.3, 0.26, 0.03)
				var sign_ := Vector3(0.035, 0.1, 0.12) if o["dir"] == "h" else Vector3(0.12, 0.1, 0.035)
				body.box(Vector3(0, 1.62, z), Vector3(0.04, 0.8, 0.04), Color(0.3, 0.2, 0.1))
				body.box(Vector3(0.0, 1.8, z), cloth * 1.35, Color(0.85, 0.12, 0.12))
				body.box(Vector3(0.0, 1.8, z), sign_ * 1.35, Color(0.98, 0.8, 0.25))
	var bi := MeshInstance3D.new()
	bi.mesh = body.build()
	bi.material_override = mat
	root.add_child(bi)
	parts["body"] = bi
	if o["type"] == "gate":
		for sgn in [-1, 1]:
			var pivot := Node3D.new()
			pivot.position = Vector3(0, 0.0, sgn * 0.3)
			root.add_child(pivot)
			var door := MeshKit.new()
			door.box(Vector3(0, 0.36, -sgn * 0.15), Vector3(0.1, 0.72, 0.3), wood)
			door.box(Vector3(0.06, 0.22, -sgn * 0.15), Vector3(0.03, 0.06, 0.28), iron)
			door.box(Vector3(0.06, 0.52, -sgn * 0.15), Vector3(0.03, 0.06, 0.28), iron)
			var di := MeshInstance3D.new()
			di.mesh = door.build()
			di.material_override = mat
			pivot.add_child(di)
			(parts["doors"] as Array).append({"pivot": pivot, "sgn": sgn})
	var rub := MeshKit.new()
	StoneWall.rubble(rub, o["pos"])
	var ri := MeshInstance3D.new()
	ri.mesh = rub.build()
	ri.material_override = mat
	root.add_child(ri)
	parts["rubble"] = ri
	_obj_nodes[o["id"]] = parts


func _refresh_object(o: Dictionary, animate: bool) -> void:
	var p: Dictionary = _obj_nodes[o["id"]]
	var st: String = o["state"]
	match o["type"]:
		"wall":
			p["body"].visible = st == "intact"
			p["rubble"].visible = st == "broken"
			if animate and st == "broken":
				Sfx.event("wall_break")
		"gate":
			p["body"].visible = st != "broken"
			p["rubble"].visible = st == "broken"
			if animate:
				Sfx.event("wall_break" if st == "broken" else "gate_open")
			for d: Dictionary in p["doors"]:
				var piv: Node3D = d["pivot"]
				piv.visible = st != "broken"
				var angle := 0.0 if st == "closed" else float(d["sgn"]) * 90.0
				if animate and st == "open":
					piv.create_tween().tween_property(piv, "rotation_degrees:y", angle, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				else:
					piv.rotation_degrees.y = angle
		"switch":     # Hebel-Sprite: umgelegt = gespiegelt
			if animate:
				Sfx.event("switch")
			var sw := p["body"] as Node3D
			var sx := absf(sw.scale.x) * (-1.0 if st == "on" else 1.0)
			if animate:
				var swt := create_tween()
				swt.tween_property(sw, "scale:x", sx * 0.4, 0.1)
				swt.tween_property(sw, "scale:x", sx, 0.15)
			else:
				sw.scale.x = sx
		"fire":
			(p["flames"] as Node3D).visible = st == "burning"
			if animate:
				Sfx.event("fire" if st == "burning" else "extinguish")
			if animate and st == "burning":
				fx.light_flash(to_world(o["pos"]) + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.2), 2.0, 3.5, 0.5)
			elif animate:
				fx.particles("fx_smoke", to_world(o["pos"]) + Vector3(0, 0.2, 0), 7, 1.3, 0.5, 0.8, -0.3, Color(0.85, 0.85, 0.85), false, 70.0)
		"house":
			(p["body"] as Node3D).visible = st != "ruin"
			(p["rubble"] as Node3D).visible = st == "ruin"
			(p["flames"] as Node3D).visible = st == "burning"
			((p["body"] as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("tint", Color(0.55, 0.45, 0.4) if st == "burning" else Color.WHITE)
			if animate:
				Sfx.event("fire" if st == "burning" else ("ruin" if st == "ruin" else "extinguish"))
			if animate and st == "burning":
				fx.light_flash(to_world(o["pos"]) + Vector3(0, 0.7, 0), Color(1.0, 0.6, 0.2), 2.5, 4.0, 0.6)
			elif animate and st == "intact":
				fx.particles("fx_foam", to_world(o["pos"]) + Vector3(0, 0.5, 0), 12, 3.0, 0.25, 0.7, 5.0, Color.WHITE, false, 120.0)
			elif animate and st == "ruin":
				fx.particles("fx_smoke", to_world(o["pos"]) + Vector3(0, 0.3, 0), 10, 1.5, 0.7, 1.0, -0.3, Color(0.3, 0.3, 0.3), false, 70.0)
	if o["type"] == "hive_p":
		(p["body"] as Node3D).visible = st == "active"
	if not ["gate", "wall", "house"].has(o["type"]) and p["rubble"] != null:
		(p["rubble"] as Node3D).visible = false


## Karten-Objekte als Pixel-Sprites (Gemini, freigestellt): Bienenstock, Glocke, Waisenhaus, Teehaus, Schiff, Hafen-Hindernisse.
## Die Spiellogik (Sperren, Zustaende) steckt in World, hier nur die Optik.
const OBJ_SPRITE := {"hive": ["fx_bienenstock", 1.0], "hive_p": ["fx_bienenstock", 0.9], "bell": ["fx_glocke", 1.6], "orphanage": ["fx_waisenhaus", 1.9], "teahouse": ["fx_teehaus", 1.7], "tent": ["fx_zelt", 1.25], "switch": ["fx_hebel", 0.7]}
const CRATE_SPRITES := [["fx_kiste", 1.0], ["fx_fass", 1.05], ["fx_saecke", 1.0]]


## Sprite mit dem Fuss auf dem Feld (Mitte unten), size = laengste Kante in Feldern.
func _object_sprite(name: String, size: float, parent: Node3D) -> MeshInstance3D:
	var s: Vector2 = fx.tex(name).get_size()
	var h := s.y * size / maxf(s.x, s.y)
	return fx.make_sprite(name, Vector3(0, h * 0.5 - 0.04, 0), size, false, Color.WHITE, 0, parent)


func _make_ch5_object(o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	add_child(root)
	var parts := {"root": root, "body": null, "rubble": null, "doors": [], "lever": null}
	match o["type"]:
		"crate":     # je Feld eines von drei Sprites (Kistenstapel, Faesser, Saecke)
			var c: Array = CRATE_SPRITES[(int(o["pos"].x) + 2 * int(o["pos"].y)) % 3]
			parts["body"] = _object_sprite(c[0], c[1], root)
		"ship":      # Elisabeths Piratenschiff auf dem Wasser, leicht schaukelnd
			# Der Rumpf taucht ein Stueck ins Wasser (die Wasserflaeche verdeckt den unteren Rand), dazu Schaum und dunkle Wasserlinie
			var sh := fx.make_sprite("fx_schiff", Vector3(0, 0.98, 0), 2.8, false, Color.WHITE, 0, root)
			var sm := ShaderMaterial.new()
			sm.shader = load("res://shaders/ship_sprite.gdshader")
			sm.set_shader_parameter("tex", fx.tex("fx_schiff"))
			sh.material_override = sm
			var rock := sh.create_tween().set_loops()
			rock.tween_property(sh, "position:y", 1.02, 1.7).set_trans(Tween.TRANS_SINE)
			rock.tween_property(sh, "position:y", 0.94, 1.7).set_trans(Tween.TRANS_SINE)
			var shadow := fx.make_flat("soft", Vector3(0.05, 0.015, 0.0), 3.0, Color(0.02, 0.1, 0.2, 0.5))
			shadow.scale = Vector3(1.0, 0.5, 1.0)
			var foam1 := fx.make_flat("ring", Vector3(0.0, 0.03, 0.05), 2.5, Color(1, 1, 1, 0.38), true)
			var foam2 := fx.make_flat("ring", Vector3(0.0, 0.03, 0.05), 3.0, Color(1, 1, 1, 0.2), true)
			for f: MeshInstance3D in [shadow, foam1, foam2]:
				f.get_parent().remove_child(f)
				root.add_child(f)
			foam1.scale = Vector3(1.0, 1.0, 0.45)
			foam2.scale = Vector3(1.0, 1.0, 0.45)
			var pulse := foam1.create_tween().set_loops()
			pulse.tween_property(foam1, "scale", Vector3(1.1, 1.0, 0.5), 1.7).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(foam1, "scale", Vector3(1.0, 1.0, 0.45), 1.7).set_trans(Tween.TRANS_SINE)
			var pulse2 := foam2.create_tween().set_loops()
			pulse2.tween_property(foam2, "scale", Vector3(0.94, 1.0, 0.41), 2.1).set_trans(Tween.TRANS_SINE)
			pulse2.tween_property(foam2, "scale", Vector3(1.04, 1.0, 0.47), 2.1).set_trans(Tween.TRANS_SINE)
			parts["body"] = sh
		"bell":      # der ganze Sprite wackelt beim Laeuten um den Fuss
			var piv := Node3D.new()
			root.add_child(piv)
			parts["body"] = _object_sprite("fx_glocke", 1.6, piv)
			parts["lever"] = piv
		_:
			var def: Array = OBJ_SPRITE[o["type"]]
			parts["body"] = _object_sprite(def[0], def[1], root)
	if o["type"] == "orphanage":
		var offs := [Vector3(-0.42, 0, 0.62), Vector3(0.0, 0, 0.7), Vector3(0.42, 0, 0.62)]
		for j in 3:
			var tex := _portrait_tex(["kind_lotte", "kind_pip", "kind_mia"][j])
			var sp := Sprite3D.new()
			sp.texture = tex
			sp.pixel_size = (0.75 if j < 2 else 0.55) / maxf(tex.get_width(), tex.get_height())
			sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sp.shaded = false
			sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
			sp.offset = Vector2(0, tex.get_height() / 2.0)
			sp.position = (offs[j] as Vector3) + Vector3(0, 0.08, 0)
			root.add_child(sp)
	_obj_nodes[o["id"]] = parts


## Gefesselte Geisel: Figur an einem Pfosten. Befreit rennt sie davon (_refresh_object).
func _make_hostage(o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	add_child(root)
	var tex := _portrait_tex(o.get("figure", "mutter"))
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = 1.2 / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.offset = Vector2(0, tex.get_height() / 2.0)
	sp.position = Vector3(0, 0.08, 0)
	root.add_child(sp)
	var post := _object_sprite("fx_pfahl", 0.8, root)      # Pfahl mit Seilen hinter der Gefangenen
	post.position.z = -0.12
	var mi := post
	_obj_nodes[o["id"]] = {"root": root, "body": mi, "rubble": null, "doors": [], "lever": null, "sprite": sp}


## Haus (Fachwerk) oder Feuerfeld; Flammen sind Partikel mit warmem Schein, ein/aus je nach Zustand.
func _make_burnable(o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	add_child(root)
	var parts := {"root": root, "body": Node3D.new(), "rubble": Node3D.new(), "doors": [], "lever": null, "flames": Node3D.new()}
	root.add_child(parts["body"])
	root.add_child(parts["rubble"])
	root.add_child(parts["flames"])
	var big: bool = o["type"] == "house"
	if big:      # Haus als Pixel-Sprite (Variante nach Position, in der Wueste Lehmhaeuser), Ruine als zweiter Sprite
		var h: int = (int(o["pos"].x) * 7 + int(o["pos"].y) * 13) % 3
		var name := ("fx_haus_wueste%d" % (1 + h % 2)) if map_data.get("biome", "") == "wueste" else "fx_haus%d" % (1 + h)
		if o.get("look", "") != "":     # Sonderhaus (z. B. Dr. Humbugs Praxis)
			name = o["look"]
		root.remove_child(parts["body"])
		(parts["body"] as Node).queue_free()
		parts["body"] = _object_sprite(name, 1.15, root)
		root.remove_child(parts["rubble"])
		(parts["rubble"] as Node).queue_free()
		parts["rubble"] = _object_sprite("fx_ruine%d" % (1 + h % 2), 1.1, root)
	var fl: Node3D = parts["flames"]
	var s: float = 1.5 if big else 1.0
	fx.make_sprite("soft", Vector3(0, 0.45 * s, 0), 1.4 * s, true, Color(1.0, 0.5, 0.12, 0.85), 0, fl)
	fx._loop_particles(fl, "fx_fireball", Vector3(0, 0.15 * s, 0), 6, 0.8, 0.5 * s, 0.8, -1.6, Color(1.0, 0.7, 0.3), true)
	fx._loop_particles(fl, "fx_smoke", Vector3(0, 0.7 * s, 0), 3, 0.5, 0.55 * s, 1.7, -0.5, Color(0.3, 0.3, 0.3, 0.8))
	var tw := fl.create_tween().set_loops()
	tw.tween_property(fl, "scale", Vector3(1.0, 1.12, 1.0), 0.18)
	tw.tween_property(fl, "scale", Vector3(1.0, 0.92, 1.0), 0.22)
	_obj_nodes[o["id"]] = parts


## Welt hat sich veraendert: Sperren neu setzen, Darstellung anpassen, Ausloeser pruefen.
func _after_world_change(changed: Array[Dictionary], quiet := false) -> void:
	grid.blocked = world.blocked()
	for c in changed:
		if not _obj_nodes.has(c["id"]):
			_make_object(c)
		_refresh_object(c, true)
	_update_fire_preview()
	await get_tree().create_timer(0.6).timeout
	if quiet:
		return
	for c in changed:
		await _run_triggers("object", {"id": c["id"], "state": c["state"]})


## Objekte, auf die die Faehigkeit id von Feld pos aus wirkt (nach ihren Marken).
func _obj_targets(u: Dictionary, id: String, pos: Vector2i) -> Array[Dictionary]:
	var ab: Dictionary = abilities[id]
	var out: Array[Dictionary] = []
	if ab["target"] == "self" or not ab.has("range"):
		return out
	var r: Array = ab["range"]
	for o in world.objects:
		var d := Grid.dist(pos, o["pos"])
		if d < r[0] or d > r[1]:
			continue
		var sol := world.solution(o, ab.get("caps", []))
		if sol.is_empty() or sol["cap"] == "throw_ally":
			continue
		if ab.get("shape", "") == "line" and o["pos"].x != pos.x and o["pos"].y != pos.y:
			continue
		if sol["cap"] == "leap":
			var land: Vector2i = o["pos"] + (o["pos"] - pos)
			if d != 1 or not _tile_free(land, u):
				continue
		out.append(o)
	return out


## Tore, die ein normaler Angriff aufbrechen kann (Sicherheitsnetz fuer jede Gruppe).
func _attack_objs(u: Dictionary, pos: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if u["team"] != "p":
		return out
	for o in world.objects:
		if World.attackable(o) and Combat.in_range(u, Grid.dist(pos, o["pos"])):
			out.append(o)
	return out


func _landing_tiles_for(ally: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var p: Vector2i = ally["pos"] + Vector2i(dx, dy)
			if (dx != 0 or dy != 0) and absi(dx) + absi(dy) <= 4 and _tile_free(p, ally):
				out.append(p)
	return out


func _object_forecast(o: Dictionary) -> String:
	var name: String = World.defs()[o["type"]]["name"]
	if _target_kind == "item":
		return "%s: Feuer löschen (%s)\nEin Fass für die Flammen, kein Heilen." % [Items.consumables()[_cur_item]["name"], name]
	if _target_kind == "douse":
		return "Feuer löschen: %s\nLöscht dieses Feld. Brunhildes Fasswurf löscht gleich mehrere." % name
	if _target_kind == "attack":
		var dmg := World.hit_damage(o, Combat.stat(sel, "atk"))
		return "%s angreifen: %d Schaden (%d/%d)\nSicherer Weg, aber langsam" % [name, dmg, o["hp"], o["maxhp"]]
	var ab: Dictionary = abilities[_cur_ab]
	var sol := world.solution(o, ab.get("caps", []))
	var what := {"break": "zerstört", "open": "öffnet", "toggle": "umlegen", "pass": "überwinden", "extinguish": "löschen (Umkreis 1)"}
	return "%s: %s %s\n%s" % [ab["name"], name, what.get(sol.get("effect", ""), ""), ab["text"]]


func _begin_landing(ally: Dictionary) -> void:
	_landing_ally = ally
	_landing_tiles = _landing_tiles_for(ally)
	_target_kind = "landing"
	_target_units = []
	_target_objs = []
	var tiles := {sel["pos"]: COL_SELF, ally["pos"]: COL_HEAL}
	for p in _landing_tiles:
		tiles[p] = Color(1.0, 0.82, 0.25, 0.45)
	_show_tiles(tiles)
	_hint.text = "Landefeld wählen (bis 4 Felder weit). Rechtsklick = zurück."


func _do_tile_ability(p: Vector2i) -> void:
	var u := sel
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	await _run_ability(u, _cur_ab, {"pos": p, "tile": true})
	if state == State.OVER:
		return
	_finish_unit_after(u)


func _do_throw_ally(dest: Vector2i) -> void:
	var u := sel
	var ally := _landing_ally
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	Items.start_cooldown(u, _cur_ab, int(abilities[_cur_ab]["cd"]))
	_turn_towards(u, ally["pos"])
	_banner(abilities[_cur_ab]["name"])
	await fx.squash(u, 1.18, 0.85, 0.3)
	await fx.leap(ally, dest, 2.4, 0.75, 2.0)
	await _run_triggers("enter", dest, ally)
	_check_end()
	if state == State.OVER:
		return
	_finish_unit_after(u)


func _act_object(u: Dictionary, o: Dictionary) -> void:
	var free := false
	if _target_kind == "ability":
		free = await _use_on_object(u, _cur_ab, o)
	elif _target_kind == "douse":
		await _douse(u, o)
	elif _target_kind == "item":
		await _use_item_on_object(u, _cur_item, o)
	else:
		await _attack_object(u, o)
	_check_end()
	if state == State.OVER:
		return
	if free and u["hp"] > 0:
		_acted = true
		_enter_action()
		return
	_finish_unit_after(u)


## Faehigkeit auf ein Objekt. Rueckgabe: true, wenn die Aktion nicht verbraucht ist (Stabsprung).
func _use_on_object(u: Dictionary, id: String, o: Dictionary) -> bool:
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	var ab: Dictionary = abilities[id]
	var sol := world.solution(o, ab.get("caps", []))
	Items.start_cooldown(u, id, int(ab["cd"]))
	_turn_towards(u, o["pos"])
	_banner(ab["name"])
	var at := to_world(o["pos"]) + Vector3(0, 0.45, 0)
	var from := fx.chest(u, 0.7)
	var also: Array[Dictionary] = []
	match sol["cap"]:
		"extinguish":   # Fass voll Bier: loescht das Zielfeld und alle brennenden Nachbarn
			await fx.projectile("fx_barrel", fx.chest(u, 1.0), at, 0.5, 1.5, 0.8, 6.0)
			fx.particles("fx_foam", at, 16, 3.5, 0.28, 0.8, 6.0, Color(1.0, 0.9, 0.6), false, 130.0)
			fx.particles("soft", at, 14, 3.0, 0.14, 0.7, 8.0, Color(0.9, 0.6, 0.15), false, 110.0)
			fx.shake(0.06, 0.2)
			for other in world.objects:
				if other != o and world.is_burning(other) and Grid.dist(other["pos"], o["pos"]) <= 1:
					also.append(other)
		"leap":
			var land: Vector2i = o["pos"] + (o["pos"] - u["pos"])
			await fx.squash(u, 1.18, 0.78, 0.22)
			await fx.leap(u, land, 1.6, 0.7, 1.0)
			await _run_triggers("enter", land, u)
		"blast":
			await fx.projectile("fx_cannonball", fx.chest(u, 0.55), at, 0.5, 1.8, 0.45, 4.0, "fx_smoke")
			fx._explosion(at, 1.0)
		"melt":
			await fx.beam(from, Vector3(at.x, from.y, at.z), Color(1.0, 0.2, 0.1), 0.25, 0.45)
			fx.light_flash(at, Color(1.0, 0.5, 0.2), 3.0, 4.0, 0.4)
			fx.particles("fx_star", at, 8, 3.0, 0.2, 0.6, 5.0, Color(1.0, 0.6, 0.3), true, 120.0)
		"smash":
			await fx.lunge(u, at, 0.6, 0.22)
			fx.shake(0.08, 0.25)
			fx.particles("fx_smoke", at, 8, 2.0, 0.4, 0.6, 1.0, Color(0.85, 0.8, 0.7), false, 90.0)
		"ranged_hit":
			await fx.projectile("fx_bone" if id == "knochenwurf" else "fx_cannonball", from, at, 0.4, 0.9, 0.5, 8.0)
			var st := fx.make_sprite("fx_star", at, 0.7, true)
			fx.pop(st, 1.8, 0.25, 0.5)
	if sol["effect"] != "pass":
		var ch := world.apply(o, sol["effect"])
		for other in also:
			ch.append_array(world.apply(other, "extinguish"))
		await _after_world_change(ch)
	return not ab.get("ends_turn", true)


func _attack_object(u: Dictionary, o: Dictionary) -> void:
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	_turn_towards(u, o["pos"])
	var at := to_world(o["pos"]) + Vector3(0, 0.45, 0)
	if Grid.dist(u["pos"], o["pos"]) <= 1:
		await fx.lunge(u, at, 0.5, 0.2)
	else:
		await fx.projectile("fx_bolt", fx.chest(u, 0.7), at, 0.3, 0.5, 0.45)
	var dmg := World.hit_damage(o, Combat.stat(u, "atk"))
	var destroyed := world.damage(o, dmg)
	fx.particles("fx_smoke", at, 5, 1.5, 0.3, 0.5, 2.0, Color(0.85, 0.8, 0.7), false, 90.0)
	fx.shake(0.04, 0.15)
	await _popup(o, "-%d  (%d/%d)" % [dmg, o["hp"], o["maxhp"]], Color(1.0, 0.8, 0.4))
	if destroyed:
		await _after_world_change([o])


func _use_switch(u: Dictionary, o: Dictionary) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	await _after_world_change(world.apply(o, "toggle"))
	_check_end()
	if state == State.OVER:
		return
	_finish_unit_after(u)


func _ring_bell(u: Dictionary, o: Dictionary) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	_actor = u
	await _after_world_change(world.apply(o, "ring"))
	_check_end()
	if state == State.OVER:
		return
	_finish_unit_after(u)


## Gefesselte Geisel auf einem Nachbarfeld ({} wenn keine).
func _hostage_near(p: Vector2i) -> Dictionary:
	for o in world.objects:
		if o["type"] == "hostage" and o["state"] == "bound" and Grid.dist(p, o["pos"]) == 1:
			return o
	return {}


## Befreien braucht zwei Runden und eine Geisel ohne Wache daneben. Rueckgabe: {text, enabled} fuer den Menuepunkt.
func _hostage_option(o: Dictionary) -> Dictionary:
	if _hostage_guards(o) > 0:
		return {"text": "Befreien (Wache!)", "enabled": false}
	var p: int = o.get("progress", 0)
	if p == 0:
		return {"text": "Fesseln lösen (1/2)", "enabled": true}
	if turn <= int(o["cut_turn"]):
		return {"text": "Befreien (ab nächster Runde)", "enabled": false}
	return {"text": "Befreien (2/2)", "enabled": true}


func _hostage_guards(o: Dictionary) -> int:
	var n := 0
	for e in units:
		if e["team"] == "e" and Grid.dist(e["pos"], o["pos"]) == 1:
			n += 1
	return n


## Zu Beginn der Heldenphase: Fesseln, an denen niemand mehr steht, ziehen sich wieder zu.
func _retie_check() -> void:
	for o in world.objects:
		if o["type"] != "hostage" or o["state"] != "bound" or int(o.get("progress", 0)) == 0:
			continue
		var held := false
		for u in units:
			if u["team"] == "p" and Grid.dist(u["pos"], o["pos"]) == 1:
				held = true
		if not held:
			o["progress"] = 0
			await _popup({"pos": o["pos"]}, "Die Fesseln sind wieder fest", Color(1.0, 0.6, 0.4))


func _free_hostage(u: Dictionary, o: Dictionary) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	_actor = u
	if int(o.get("progress", 0)) == 0:
		o["progress"] = 1
		o["cut_turn"] = turn
		Sfx.event("rope")
		await _popup(u, "Fesseln angeritzt\n(1/2)", Color(1.0, 0.9, 0.5))
		_finish_unit_after(u)
		return
	await _popup(u, "Befreit!", Color(0.6, 1.0, 0.6))
	await _after_world_change(world.apply(o, "free"))
	_check_end()
	if state == State.OVER:
		return
	_finish_unit_after(u)


## Verteidigen: Zug endet, bis zur naechsten eigenen Phase halber Schaden (Tanks x0,4), kein Gegenschlag.
func _defend(u: Dictionary) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	Status.add(u, "defend", 1)
	_refresh_unit(u)
	fx.defend_fx(u)
	await _popup(u, "Verteidigt", Color(0.55, 0.78, 1.0))
	_finish_unit_after(u)


## Orange Felder: hier faengt das Feuer in der naechsten Feuerphase (zu Beginn der Gegnerphase).
func _update_fire_preview() -> void:
	if _fire_preview == null:
		return
	for c in _fire_preview.get_children():
		c.queue_free()
	var m := _mat(Color(1.0, 0.45, 0.1, 0.38), true, true)
	for p: Vector2i in world.ignition_preview(_flammable):
		var mi := MeshInstance3D.new()
		mi.mesh = terrain.tile_mesh(p, 0.47, 0.055)
		mi.material_override = m
		_fire_preview.add_child(mi)


## Eine Feuerphase: Feuer breitet sich aus, altert, Haeuser werden zu Ruinen.
func _fire_phase() -> void:
	var any := false
	for o in world.objects:
		if world.is_burning(o):
			any = true
	if not any:
		return
	var changed := world.tick_fire(_flammable)
	if not changed.is_empty():
		await _after_world_change(changed, true)
	_check_end()


func _burn(u: Dictionary) -> void:
	_count({}, u, mini(FIRE_DAMAGE, u["hp"]))
	u["hp"] = maxi(0, u["hp"] - FIRE_DAMAGE)
	_refresh_unit(u)
	fx.flash_unit(u, Color(2.0, 1.2, 0.6), 0.25)
	await _popup(u, "-%d Feuer" % FIRE_DAMAGE, Color(1.0, 0.6, 0.2))
	if u["hp"] <= 0:
		units.erase(u)
		_away.erase(u)
		await _down(u)
		fx.death(u)


func _douse_targets(u: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in world.objects:
		if world.is_burning(o) and Grid.dist(u["pos"], o["pos"]) <= 1:
			out.append(o)
	return out


## Feuer austreten/loeschen mit blossen Haenden und Stiefeln: loescht 1 Feld. Jeder kann es (Sicherheitsnetz).
func _douse(u: Dictionary, o: Dictionary) -> void:
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	_turn_towards(u, o["pos"])
	_popup(u, "Feuer löschen", Color(0.7, 0.85, 1.0))
	var at := to_world(o["pos"]) + Vector3(0, 0.3, 0)
	await fx.lunge(u, at, 0.45, 0.25)
	fx.particles("fx_smoke", at, 8, 2.0, 0.4, 0.7, -0.2, Color(0.85, 0.85, 0.85), false, 80.0)
	await _after_world_change(world.apply(o, "extinguish"))


func _has_items() -> bool:
	for id: String in inventory:
		if int(inventory[id]) > 0:
			return true
	return false


func _item_targets(u: Dictionary, id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var r := int(Items.consumables()[id].get("range", 1))
	for o in units:
		if o["team"] == u["team"] and Grid.dist(u["pos"], o["pos"]) <= r and Items.useful_on(id, o):
			out.append(o)
	return out


func _begin_item(id: String) -> void:
	_close_menu()
	_target_kind = "item"
	_cur_item = id
	_target_objs = []
	if Items.consumables()[id].get("douse", false):
		_target_objs = _douse_targets(sel)
	_target_units = _item_targets(sel, id)
	var tiles := {sel["pos"]: COL_SELF}
	for o in _target_units:
		tiles[o["pos"]] = COL_HEAL
	for ob in _target_objs:
		tiles[ob["pos"]] = Color(1.0, 0.82, 0.25, 0.6)
	_show_tiles(tiles)
	state = State.TARGETING
	_update_status()


## Gegenstand benutzen: kostet die Aktion, der Rucksack gehoert dem ganzen Team.
func _use_item(u: Dictionary, id: String, target: Dictionary) -> void:
	inventory[id] = int(inventory.get(id, 0)) - 1
	var it: Dictionary = Items.consumables()[id]
	if target != u:
		_turn_towards(u, target["pos"])
	_popup(u, it["name"], Color(1.0, 0.9, 0.5))
	var res := Items.apply_item(id, target, units.filter(func(o: Dictionary) -> bool: return o["team"] == u["team"]))
	u["st"]["healed"] += int(res["heal"])
	u["st"]["abs"] += 1
	for v: Dictionary in res["victims"]:
		_refresh_unit(v)
	if res["heal"] > 0 or res["cured"] > 0:
		Sfx.event("item")
		fx.on_heal("item", u, target, res["heal"], res["cured"] > 0)
		await _popup(target, ("+%d" % res["heal"]) + ("\nGegengift" if res["cured"] > 0 else ""), Color(0.4, 1, 0.5))
	if res["status"] > 0:
		for e: Dictionary in it["effects"]:
			if e["type"] == "reset_cd":
				fx.light_flash(fx.chest(target, 0.8), Color(0.6, 0.8, 1.0), 2.0, 3.0, 0.4)
				await _popup(target, "Bereit!", Color(0.6, 0.85, 1.0))
			elif e["type"] == "status":
				var good: bool = Status.GOOD.has(e["id"])
				for v: Dictionary in res["victims"]:
					_popup(v, Status.NAMES[e["id"]], Color(0.5, 1, 0.6) if good else Color(1, 0.7, 0.3))
				await get_tree().create_timer(0.5).timeout
	_refresh_unit(target)


## Gegenstand (Bier) auf ein brennendes Objekt: loescht dieses eine Feld, kostet die Aktion und einen Gegenstand.
func _use_item_on_object(u: Dictionary, id: String, o: Dictionary) -> void:
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	inventory[id] = int(inventory.get(id, 0)) - 1
	_turn_towards(u, o["pos"])
	_popup(u, Items.consumables()[id]["name"], Color(1.0, 0.9, 0.5))
	var at := to_world(o["pos"]) + Vector3(0, 0.4, 0)
	await fx.projectile("fx_barrel", fx.chest(u, 1.0), at, 0.4, 1.0, 0.6, 6.0)
	fx.particles("fx_foam", at, 14, 3.0, 0.26, 0.8, 6.0, Color(1.0, 0.9, 0.6), false, 130.0)
	await _after_world_change(world.apply(o, "extinguish"))


func _begin_targeting(kind: String) -> void:
	_close_menu()
	_target_kind = kind
	_target_units = []
	_target_objs = []
	if kind == "attack":
		_target_units = _attack_targets(sel, sel["pos"])
		_target_objs = _attack_objs(sel, sel["pos"])
	elif kind == "douse":
		_target_objs = _douse_targets(sel)
	else:
		_target_units = _heal_targets(sel, sel["pos"])
	var tiles := {sel["pos"]: COL_SELF}
	for o in _target_units:
		tiles[o["pos"]] = COL_ATTACK if kind == "attack" else COL_HEAL
	for o in _target_objs:
		tiles[o["pos"]] = COL_ATTACK
	_show_tiles(tiles)
	state = State.TARGETING
	_update_status()


func _walk(u: Dictionary, goal: Vector2i) -> void:
	var path := grid.path_to(u["pos"], goal, reach, u["flying"])
	var tw := create_tween()
	var run := 0
	var last := Vector2i.ZERO
	for i in range(1, path.size()):
		tw.tween_callback(_face_step.bind(u, path[i] - path[i - 1]))
		tw.tween_property(u["node"], "position", to_world(path[i]), 0.14)
		var d: Vector2i = path[i] - path[i - 1]
		run = run + 1 if d == last else 1
		last = d
	u["charge"] = mini(run, 3)   # Sturmangriff: Laenge des letzten geraden Laufs
	u["pos"] = goal
	if path.size() > 1:
		await tw.finished
	else:
		tw.kill()


func _finish_unit(u: Dictionary) -> void:
	u["done"] = true
	_refresh_unit(u)
	sel = {}
	_show_tiles({})
	_show_card({})
	state = State.IDLE
	_update_status()
	if _all_done("p"):
		_end_player_turn()


func _all_done(team: String) -> bool:
	for p in units:
		if p["team"] == team and not p["done"]:
			return false
	return true


func _act(u: Dictionary, target: Dictionary) -> void:
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	var free_ability := false
	if _target_kind == "item":
		await _use_item(u, _cur_item, target)
	elif _target_kind == "ability":
		free_ability = not abilities[_cur_ab].get("ends_turn", true)
		await _run_ability(u, _cur_ab, target)
	else:
		await _resolve(u, target)
	if state == State.OVER:
		return
	if free_ability and u["hp"] > 0:
		_acted = true
		await _flush_events()
		_enter_action()
		return
	_finish_unit_after(u)


func _finish_unit_after(u: Dictionary) -> void:
	if state != State.OVER:
		state = State.BUSY          # waehrend Ereignisse laufen (Dialoge), keine Eingabe
		await _flush_events()
	if state == State.OVER:
		return
	state = State.IDLE
	if u["hp"] > 0:
		_finish_unit(u)
	else:
		sel = {}
		_show_card({})
		_update_status()
		_check_end()


## Angriff oder Heilung samt Gegenschlag.
func _resolve(u: Dictionary, target: Dictionary) -> void:
	if target["team"] == u["team"]:
		var amount := mini(u["heal"], target["maxhp"] - target["hp"])
		_actor = u
		if amount > 0:
			_note("heal", {"by": u, "healed": [target]})
		target["hp"] += amount
		u["st"]["healed"] += amount
		var cured := Status.cleanse(target)
		_refresh_unit(target)
		Sfx.event("heal")
		await _popup(target, ("+%d" % amount) + ("\nGegengift" if cured else ""), Color(0.4, 1, 0.5))
		return
	await _strike(u, target)
	var dist := Grid.dist(u["pos"], target["pos"])
	if target["hp"] > 0 and Combat.can_counter(target, dist):
		await _strike(target, u)
	_check_end()


func _strike(att: Dictionary, def: Dictionary, mult := 1.0, ignore_def := 0.0, lunge := true, quick := false) -> void:
	_actor = att
	var fc := forecast(att, def, att["pos"], mult, ignore_def)
	var dmg: int = fc["dmg"]
	_count(att, def, mini(dmg, def["hp"]))
	if not (fc["tags"] as Array).is_empty():
		att["st"]["bonus"] += 1                 # Treffer mit Positionsbonus (Ruecken, Flanke, Hoehe, Hinterhalt)
	def["hp"] = maxi(0, def["hp"] - dmg)
	Status.remove(att, "stealth")
	if lunge:
		_turn_towards(att, def["pos"])
		_turn_towards(def, att["pos"])
		if Grid.dist(att["pos"], def["pos"]) > 1:
			await fx.basic_shot(att, def)
		if Grid.dist(att["pos"], def["pos"]) <= 1:
			Sfx.swing(att)
		var n: Node3D = att["node"]
		var start := n.position
		var dir := to_world(def["pos"]) - start
		dir.y = 0.0
		var toward := dir.normalized() * 0.3
		var tw := create_tween()
		tw.tween_property(n, "position", start + toward, 0.08)
		tw.tween_property(n, "position", start, 0.1)
		await tw.finished
		fx.basic_hit(att, def, not fc["tags"].is_empty())
	_refresh_unit(att)
	_refresh_unit(def)
	var tag_text := "\n" + ", ".join(fc["tags"]) if not fc["tags"].is_empty() else ""
	if quick:
		_popup(def, "-%d%s" % [dmg, tag_text], Color(1, 0.45, 0.35))   # nicht abwarten (Serientreffer)
	else:
		await _popup(def, "-%d%s" % [dmg, tag_text], Color(1, 0.45, 0.35))
	if def["hp"] <= 0:
		units.erase(def)
		await _down(def)


const POPUP_MAX := 3          # so viele Meldungen gleichzeitig je Figur
const POPUP_GAP := 0.22       # Mindestabstand zwischen zwei Meldungen derselben Figur (Sekunden Spielzeit)


## Kurzmeldung an einer Figur (Schaden, Heilung, Status). Gestaffelt: je Figur eine Warteschlange, hoechstens POPUP_MAX gleichzeitig,
## gleiche Texte werden zu "xN" zusammengefasst, die Meldungen steigen abwechselnd links und rechts neben der Figur auf (nicht ueber dem Kopf,
## dort stehen Balken und Symbole). Schaden gross, Heilung mittel, Status klein. Fahigkeitsnamen laufen ueber _banner.
func _popup(u: Dictionary, text: String, color: Color) -> void:
	var key: String = u.get("uid", "%d_%d" % [u["pos"].x, u["pos"].y])
	var live: Array = _popup_live.get(key, [])
	for e: Dictionary in live:
		if e["base"] == text and _clock - float(e["t0"]) < 0.8:
			e["n"] = int(e["n"]) + 1
			(e["label"] as Label3D).text = "%s ×%d" % [text, e["n"]]
			return
	var start := maxf(_clock, float(_popup_next.get(key, 0.0)))
	_popup_next[key] = start + POPUP_GAP
	if start > _clock:
		await get_tree().create_timer(start - _clock).timeout
	live = _popup_live.get(key, [])
	while live.size() >= POPUP_MAX:
		await get_tree().create_timer(0.1).timeout
		live = _popup_live.get(key, [])
	var dmg := text.begins_with("-") and text.length() > 1 and text[1].is_valid_int()
	var heal := text.begins_with("+")
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font = UiTheme.font(UiTheme.F_TITLE)
	l.font_size = 72 if dmg else (60 if heal else 52)
	l.pixel_size = (0.0105 if dmg else (0.0085 if heal else 0.0058)) * popup_scale
	if "\n" in text and not dmg and not heal:
		l.pixel_size = 0.0058 * popup_scale
	l.outline_size = 16
	l.modulate = color
	l.no_depth_test = true
	l.render_priority = 8
	var cnt := int(_popup_count.get(key, 0))
	_popup_count[key] = cnt + 1
	var side := -1.0 if cnt % 2 == 0 else 1.0
	var entry := {"label": l, "base": text, "n": 1, "t0": _clock}
	live.append(entry)
	_popup_live[key] = live
	var cu := cam.global_transform.basis.y.normalized() if cam != null else Vector3.UP
	var cr := cam.global_transform.basis.x.normalized() if cam != null else Vector3.RIGHT
	var base := to_world(u["pos"]) + cr * side * 0.55 + cu * (0.75 + 0.3 * float(live.size() - 1))
	l.position = base
	add_child(l)
	if dmg:
		l.scale = Vector3.ONE * 1.6
		create_tween().tween_property(l, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var life := 1.1 if (dmg or "\n" in text) else 0.9
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position", base + cu * 0.8, life)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.4).set_delay(life * 0.6)
	tw.chain().tween_callback(func() -> void:
		var lv: Array = _popup_live.get(key, [])
		lv.erase(entry)
		_popup_live[key] = lv
		l.queue_free())
	await get_tree().create_timer(0.45).timeout


## Name einer Faehigkeit als Banner oben im Bild (unter dem Rundenband), damit er nicht mit Schaden und Status an der Figur kollidiert.
func _banner(text: String, color := Color(1.0, 0.9, 0.5)) -> void:
	if _hud_root == null:
		return
	if _banner_label == null:
		_banner_label = Label.new()
		_banner_label.position = Vector2(0, 50)
		_banner_label.size = Vector2(1280, 40)
		_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner_label.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
		_banner_label.add_theme_font_size_override("font_size", 30)
		_banner_label.add_theme_constant_override("outline_size", 10)
		_banner_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
		_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_root.add_child(_banner_label)
	_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_label.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_label, "modulate:a", 1.0, 0.12)
	_banner_tween.tween_interval(1.0)
	_banner_tween.tween_property(_banner_label, "modulate:a", 0.0, 0.3)


func _count_team(team: String) -> int:
	var n := 0
	for u in units + _away:
		if u["team"] == team:
			n += 1
	return n


## Ist das Missionsziel erreicht? (Verloren: alle Helden gefallen, siehe _check_end)
func goal_met() -> bool:
	match goal.get("type", "rout"):
		"survive":
			return turn > int(goal["turns"])
		"free":
			return world.by_id(goal["id"])["state"] == "free"
		"capture":
			var cu := _find(str(goal["unit"]))
			return not cu.is_empty() and cu["team"] == "p"
		"reach":
			var t := Vector2i(goal["tile"][0], goal["tile"][1])
			for u in units:
				if u["team"] == "p" and u["pos"] == t:
					return true
			return false
		_:
			return _count_team("e") == 0


func _check_end() -> void:
	if state == State.OVER:
		return
	var lost := _count_team("p") == 0
	var won := not lost and goal_met()
	if won or lost:
		state = State.OVER
		_show_tiles({})
		_close_menu()
		_hint.text = ""
		_status.text = "Sieg!" if won else "Niederlage"
		Sfx.event("victory" if won else "defeat")
		await get_tree().create_timer(1.2).timeout
		finished.emit(won)


# ------------------------------------------------------------------ Ausloeser

## Feuert alle passenden, noch nicht ausgeloesten Ausloeser. kind: "turn" (data = Runde) oder "enter" (data = Feld).
func _run_triggers(kind: String, data: Variant, who := {}) -> void:
	for t: Dictionary in triggers:
		if t.get("fired", false):
			continue
		var w: Dictionary = t["when"]
		var hit := false
		if kind == "turn" and w.has("turn"):
			hit = int(w["turn"]) == int(data)
		elif kind == "enter" and w.has("enter"):
			hit = Vector2i(w["enter"][0], w["enter"][1]) == data
		elif kind == "object" and w.has("object"):
			hit = w["object"]["id"] == data["id"] and w["object"]["state"] == data["state"]
		if hit and _cond_ok(t.get("if", {})):    # Bedingung nicht erfuellt: Ausloeser bleibt fuer spaeter erhalten
			t["fired"] = true
			await _fire(t, who)


## Bedingung eines Ausloesers: {"object": {"id", "state"}} = Objekt hat diesen Zustand.
func _cond_ok(c: Dictionary) -> bool:
	for id: String in c.get("fled", []):        # diese Gegner sind in einer frueheren Mission geflohen
		if not nemeses.has(id):
			return false
	for id: String in c.get("present", []):     # alle diese Figuren leben noch
		if _find(id).is_empty():
			return false
	for id: String in c.get("absent", []):      # keine dieser Figuren lebt noch
		if not _find(id).is_empty():
			return false
	if c.has("object"):
		var o := world.by_id(c["object"]["id"])
		return not o.is_empty() and o["state"] == c["object"]["state"]
	return true


# ------------------------------------------------------------------ Ereignisse

## Erste lebende Einheit mit dieser ID ({} wenn keine).
func _find(id: String) -> Dictionary:
	for u in units:
		if u["id"] == id:
			return u
	return {}


func _note(kind: String, data: Dictionary) -> void:
	var n := data.duplicate()
	n["kind"] = kind
	_notes.append(n)


## Passt ein Ereignis (Notiz) zu "when"? Rueckgabe: ausloesende Figur oder {} (kein Treffer).
func _match_note(w: Dictionary, n: Dictionary) -> Dictionary:
	match n["kind"]:
		"heal":
			if w.has("heal"):
				var c: Dictionary = w["heal"]
				if c.get("by", "") in ["", n["by"]["id"]] and (n["healed"] as Array).size() >= int(c.get("targets", 1)):
					return n["by"]
		"ability":
			if w.has("ability"):
				var c2: Dictionary = w["ability"]
				if c2.get("id", n["id"]) == n["id"] and c2.get("by", n["by"]["id"]) == n["by"]["id"]:
					return n["by"]
		"death":
			var dead: Dictionary = n["unit"]
			if dead["team"] == "e":
				if w.has("kill") and (w["kill"] as Dictionary).get("id", dead["id"]) == dead["id"] \
						and kills_total >= int((w["kill"] as Dictionary).get("count", 1)):
					return n["by"] if not (n["by"] as Dictionary).is_empty() else dead
				if w.has("first_kill") and kills_total == 1:
					return n["by"] if not (n["by"] as Dictionary).is_empty() else dead
			elif w.has("fall") and (w["fall"] as Dictionary).get("id", dead["id"]) == dead["id"]:
				return dead
	return {}


## Ereignisse, die vom Zustand abhaengen (kein einzelnes Geschehen): Naehe, Leben, Zahl der Gegner.
func _match_state(w: Dictionary) -> Dictionary:
	if w.has("hp_below"):
		var c: Dictionary = w["hp_below"]
		var u := _find(c["id"])
		if not u.is_empty() and float(u["hp"]) / float(u["maxhp"]) < float(c["ratio"]):
			return u
	if w.has("near"):
		var c2: Dictionary = w["near"]
		var a := _find(c2["a"])
		if not a.is_empty():
			for o in units:
				var okb: bool = (c2["b"] == "any_enemy" and o["team"] != a["team"]) or o["id"] == c2["b"]
				if okb and o != a and Grid.dist(a["pos"], o["pos"]) <= int(c2.get("dist", 3)):
					return a
	if w.has("enemies_left") and _count_team("e") <= int(w["enemies_left"]):
		for u in units:
			if u["team"] == "p":
				return u
	return {}


## Alle neuen Ereignisse gegen die Ausloeser der Mission pruefen (nach jeder Aktion, jeder Phase).
func _flush_events() -> void:
	var notes := _notes.duplicate()
	_notes.clear()
	for t: Dictionary in triggers:
		if t.get("fired", false):
			continue
		var w: Dictionary = t["when"]
		var who: Dictionary = {}
		for n: Dictionary in notes:
			who = _match_note(w, n)
			if not who.is_empty():
				break
		if who.is_empty():
			who = _match_state(w)
		if who.is_empty() or not _cond_ok(t.get("if", {})):
			continue
		t["fired"] = true
		await _fire(t, who)
		if state == State.OVER:
			return


## "$hero" in Dialogzeilen wird durch die ausloesende Figur ersetzt; text_by waehlt den Text je Figur.
func _hero_lines(lines: Array, who: Dictionary) -> Array:
	var out: Array = []
	var hid: String = who.get("id", "")
	for l: Dictionary in lines:
		var c := l.duplicate()
		for k in ["left", "right", "speaker"]:
			if c.get(k, "") == "$hero":
				c[k] = hid
		if c.has("text_by"):
			c["text"] = c["text_by"].get(hid, c["text_by"].get("default", ""))
		out.append(c)
	return out


func _fire(t: Dictionary, who := {}) -> void:
	for step: Dictionary in t["do"]:
		if step.has("popup") and not units.is_empty():
			var anchor: Dictionary = units[0]
			await _popup(anchor, step["popup"], Color(1.0, 0.55, 0.4))
		if step.has("dialogue") and dialogue_runner.is_valid():
			var was_visible := _hud_layer.visible
			_hud_layer.visible = false
			await dialogue_runner.call(_hero_lines(step["dialogue"], who))
			_hud_layer.visible = was_visible
		if step.has("world"):   # {"id": "gate1", "effect": "open", "quiet": true}: Objekt veraendern (quiet: keine Objekt-Ausloeser)
			var wo := world.by_id(step["world"]["id"])
			if not wo.is_empty():
				await _after_world_change(world.apply(wo, step["world"]["effect"]), step["world"].get("quiet", false))
		if step.has("later"):   # {"later": {"turns": 2, "fire": "id"}}: nach N Runden das Ereignis mit dieser id ausloesen
			_scheduled.append({"turn": turn + int(step["later"]["turns"]), "id": step["later"]["fire"]})
		if step.has("retreat"):   # {"retreat": "xiulan"}: Gegner zieht sich freiwillig zurueck (kein Tod, kehrt spaeter wieder)
			var rt := _find(step["retreat"])
			if not rt.is_empty():
				units.erase(rt)
				retreated.append(rt["id"])
				await _flee(rt, false)
		if step.has("spawn"):
			for e: Dictionary in step["spawn"]:
				var pos := _free_tile_near(Vector2i(e["pos"][0], e["pos"][1]), {"flying": false})
				_spawn(e["id"], e.get("team", "e"), pos, {"carry": e.get("carry", {})})
				var u: Dictionary = units.back()
				Sfx.event("buzz" if e["id"] == "bienenkrieger" else "")
				await _popup(u, e.get("label", "Verstärkung"), Color(0.6, 1.0, 0.6) if e.get("team", "e") == "p" else Color(1.0, 0.6, 0.4))
	_update_status()



# ------------------------------------------------------------------ Faehigkeiten

func _first_effect(ab: Dictionary, type: String) -> Dictionary:
	for ef: Dictionary in ab["effects"]:
		if ef["type"] == type:
			return ef
	return {}


func _tile_free(p: Vector2i, mover: Dictionary) -> bool:
	return grid.inside(p) and unit_at(p).is_empty() and grid.cost(p, mover["flying"]) >= 0


## Gueltige Ziele einer Faehigkeit von Feld pos aus.
func _ab_targets(u: Dictionary, id: String, pos: Vector2i) -> Array[Dictionary]:
	var ab: Dictionary = abilities[id]
	var out: Array[Dictionary] = []
	if ab["target"] == "tile":
		return out
	if ab["target"] == "self":
		out.append(u)
		return out
	var r: Array = ab["range"]
	for o in units:
		var dd := Grid.dist(pos, o["pos"])
		if dd < r[0] or dd > r[1]:
			continue
		if ab["target"] == "enemy":
			if o["team"] == u["team"]:
				if (ab.get("caps", []) as Array).has("throw_ally") and o != u and not _landing_tiles_for(o).is_empty():
					out.append(o)   # Verbuendete duerfen geworfen werden (ueber Mauern und Wasser)
				elif o != u and _secret_for(u, id, o) != {}:
					out.append(o)   # geheime Interaktion mit diesem Verbuendeten
				continue
			if Status.has(o, "stealth") or not _hittable(o):
				continue
			if ab.has("require_tag") and not (o["tags"] as Array).has(ab["require_tag"]):
				continue
			if ab.get("require_back", false) and not _from_behind(pos, o):
				continue
			if ab.get("shape", "") == "line" and o["pos"].x != pos.x and o["pos"].y != pos.y:
				continue   # Strahl: nur auf geraden Linien
			if not _first_effect(ab, "jump").is_empty():
				var land: Vector2i = o["pos"] + (o["pos"] - pos)
				if not _tile_free(land, u):
					continue
			out.append(o)
		else:
			if o["team"] != u["team"] or (o == u and ab["target"] == "ally"):
				continue
			if ab["target"] == "ally" and not _first_effect(ab, "heal").is_empty() \
					and not (o["hp"] < o["maxhp"] or Status.has(o, "poison")):
				continue
			out.append(o)
	return out


## Steht pos hinter o (entgegen dessen Blickrichtung)? Voraussetzung des Hinterhalts.
func _from_behind(pos: Vector2i, o: Dictionary) -> bool:
	var rel := Vector2(pos - o["pos"])
	return rel != Vector2.ZERO and Vector2(o["dir"]) != Vector2.ZERO and rel.normalized().dot(Vector2(o["dir"]).normalized()) < -0.5


## Zielfelder von Faehigkeiten mit target "tile" (Bienenkorb: freies Bodenfeld, Tonikum: jedes Feld in Reichweite).
func _ab_tiles(u: Dictionary, id: String, pos: Vector2i) -> Array[Vector2i]:
	var ab: Dictionary = abilities[id]
	var out: Array[Vector2i] = []
	if ab["target"] != "tile":
		return out
	var r: Array = ab["range"]
	for dy in range(-int(r[1]), int(r[1]) + 1):
		for dx in range(-int(r[1]), int(r[1]) + 1):
			var p := pos + Vector2i(dx, dy)
			var d := Grid.dist(pos, p)
			if d < r[0] or d > r[1] or not grid.inside(p):
				continue
			if _first_effect(ab, "summon_hive").is_empty():
				out.append(p)
			elif unit_at(p).is_empty() and world.at(p).is_empty() and grid.cost(p) >= 0:
				out.append(p)
	return out


# ------------------------------------------------------------------ Uebernahme (Ziel "capture")

var capture_progress := 0           # aufeinanderfolgende Spielerphasen mit einem Helden neben dem Ziel


func _capture_info() -> Dictionary:
	if goal.get("type", "") != "capture":
		return {}
	var cu := _find(str(goal["unit"]))
	return {"present": not cu.is_empty(), "progress": capture_progress, "name": cu.get("name", "")}


## Ende der Spielerphase: Steht mindestens ein Held neben dem Ziel, zaehlt die Runde, sonst beginnt die Zaehlung von vorn.
## Nach goal["turns"] Runden in Folge wechselt das Ziel die Seite (Mission gewonnen).
func _capture_phase() -> void:
	if goal.get("type", "") != "capture":
		return
	var cu := _find(str(goal["unit"]))
	if cu.is_empty() or cu["team"] != "e":
		capture_progress = 0
		return
	var near := false
	for h in units:
		if h["team"] == "p" and Grid.dist(h["pos"], cu["pos"]) == 1:
			near = true
	if not near:
		if capture_progress > 0:
			await _popup(cu, "Übernahme abgebrochen", Color(1.0, 0.6, 0.4))
		capture_progress = 0
		_update_status()
		return
	capture_progress += 1
	_update_status()
	if capture_progress < int(goal.get("turns", 3)):
		await _popup(cu, "Übernahme %d/%d" % [capture_progress, int(goal.get("turns", 3))], Color(0.6, 0.85, 1.0))
		return
	await _capture_unit(cu)
	_check_end()


## Die Figur wechselt auf die Seite der Spieler.
func _capture_unit(cu: Dictionary) -> void:
	cu["team"] = "p"
	cu["done"] = true
	cu["status"] = []
	(cu["ring"] as MeshInstance3D).material_override = _mat(TEAM_COLOR["p"])
	((cu["arrow"] as Node3D).get_child(0) as MeshInstance3D).material_override = _mat(TEAM_COLOR["p"].lerp(Color.WHITE, 0.55))
	(cu["label"] as Label3D).modulate = TEAM_COLOR["p"].lerp(Color.WHITE, 0.5)
	_refresh_unit(cu)
	Sfx.event("secret")
	fx.shockwave((cu["node"] as Node3D).position, 2.2, Color(0.4, 0.75, 1.0, 0.8), 0.7)
	fx.light_flash(fx.chest(cu, 1.0), Color(0.5, 0.8, 1.0), 4.0, 6.0, 0.8)
	fx.particles("fx_smoke", fx.chest(cu, 1.2), 12, 1.6, 0.8, 1.0, -0.3, Color(1, 1, 1, 0.8), false, 120.0)
	await _popup(cu, "Übernommen!", Color(0.6, 0.9, 1.0))
	await get_tree().create_timer(0.6).timeout


## Super-Attacke: Polarlicht-Auftritt mit dem vergroesserten Chibi, dazu eigene Musik (die Kampfmusik wird leiser).
var _super_player: AudioStreamPlayer

func _super_cutin(u: Dictionary, ab: Dictionary, title := "", sub := "") -> void:
	var stream: AudioStreamMP3 = load("res://assets/audio/super_attack.mp3")
	stream.loop = false
	_super_player = AudioStreamPlayer.new()
	_super_player.stream = stream
	_super_player.volume_db = -4.0
	add_child(_super_player)
	_super_player.play()
	if super_music.is_valid():
		super_music.call(true)
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var c := SuperCutin.new()
	c.setup((u["sprite"] as Sprite3D).texture, title if title != "" else str(ab["name"]), sub if title != "" else str(ab.get("super_sub", "")))
	layer.add_child(c)
	await c.finished
	layer.queue_free()


func _super_music_stop() -> void:
	if _super_player != null and is_instance_valid(_super_player):
		var p := _super_player
		_super_player = null
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -50.0, 0.9)
		tw.tween_callback(p.queue_free)
	if super_music.is_valid():
		super_music.call(false)


## Steht zwischen Schuetze und Ziel (gerade Linie) ein Verbuendeter, der den Strahl dieses Geheimnisses umlenkt? Rueckgabe {sec, via} oder {}.
func _beam_blocker(u: Dictionary, id: String, target: Dictionary) -> Dictionary:
	if target.get("tile", false) or target == u or not target.has("pos"):
		return {}
	var d: Vector2i = target["pos"] - u["pos"]
	if (d.x != 0 and d.y != 0) or maxi(absi(d.x), absi(d.y)) < 2:
		return {}
	var step := Vector2i(signi(d.x), signi(d.y))
	for k in range(1, maxi(absi(d.x), absi(d.y))):
		var o := unit_at(u["pos"] + step * k)
		if o.is_empty() or o["team"] != u["team"]:
			continue
		var sec := Secrets.find_beam(u["id"], id, o["id"])
		if not sec.is_empty():
			return {"sec": sec, "via": o}
	return {}


## Geheimnis "Futter fuer Brumm" (mode "catch"): Die Figur auf der Flugbahn faengt etwas auf (Heilung und ein Status mit Schadensminderung),
## der Angriff selbst bleibt unveraendert. Beim ersten Mal laeuft die Szene.
func _run_catch(u: Dictionary, via: Dictionary, sec: Dictionary) -> void:
	var ef: Dictionary = sec["effects"]
	await fx.catch_bone(u, via)
	if not secrets_seen.has(sec["id"]):
		secrets_seen.append(sec["id"])
		if secret_runner.is_valid():
			await secret_runner.call(sec)
	var amount := mini(int(ef.get("heal", 0)), via["maxhp"] - via["hp"])
	if amount > 0:
		via["hp"] += amount
		u["st"]["healed"] += amount
		_note("heal", {"by": u, "healed": [via]})
	var st: Dictionary = ef.get("status", {})
	if not st.is_empty():
		Status.add(via, str(st["id"]), int(st.get("turns", 3)), {"reduce_pct": int(st.get("reduce_pct", 25))})
	_refresh_unit(via)
	if amount > 0:
		fx.on_heal("knochenwurf", u, via, amount, false)
		_popup(via, "+%d" % amount, Color(0.4, 1, 0.5))
	await _popup(via, "Mjam!", Color(1.0, 0.85, 0.4))


## Geheimnis "Laser-Reflektor": Die Figur auf der Linie lenkt den Strahl um. Er endet dort und trifft (bzw. heilt) alle Figuren im Umkreis
## um die Figur mit einem Teil der Wirkung. Beim ersten Mal laufen Szene und grosser Auftritt, danach nur ein kurzer Effekt.
func _run_reflect(u: Dictionary, id: String, target: Dictionary, via: Dictionary, sec: Dictionary) -> void:
	var ab: Dictionary = abilities[id]
	var ef: Dictionary = sec["effects"]
	u["st"]["abs"] += 1
	Items.start_cooldown(u, id, int(ab["cd"]))
	_actor = u
	_note("ability", {"id": id, "by": u})
	_turn_towards(u, via["pos"])
	_banner(ab["name"])
	var dm := _first_effect(ab, "damage")
	var hl := _first_effect(ab, "heal")
	var healing := dm.is_empty() and not hl.is_empty()
	var col := Color(0.4, 1.0, 0.6) if healing else Color(1.0, 0.25, 0.15)
	await fx.windup(id, u, target)
	await fx.reflect_beam(u, via, col)
	var first := not secrets_seen.has(sec["id"])
	if first:
		secrets_seen.append(sec["id"])
		if secret_runner.is_valid():
			await secret_runner.call(sec)
		var ci: Dictionary = ef.get("cutin", {})
		if not ci.is_empty():
			await _super_cutin(via, ab, str(ci.get("title", ab["name"])), str(ci.get("sub", "")))
	await fx.reflect_spin(via)
	_popup(via, "Reflektiert!", Color(1.0, 0.9, 0.5))
	var pct := float(ef.get("reflect_pct", 75)) / 100.0
	var tiles := _area_tiles({"area": {"shape": "radius", "r": int(ef.get("radius", 2))}}, via["pos"])
	var victims: Array[Dictionary] = []
	for o in units:
		if not tiles.has(o["pos"]):
			continue
		if healing and o["team"] == u["team"]:
			victims.append(o)
		elif not healing and o["team"] != u["team"] and _hittable(o) and not Status.has(o, "stealth"):
			victims.append(o)
	for v in victims:
		if not units.has(v):
			continue
		await fx.reflect_beam(via, v, col)
		if healing:
			var amount := mini(roundi(float(hl["amount"]) * pct), v["maxhp"] - v["hp"])
			v["hp"] += amount
			u["st"]["healed"] += amount
			var cured: bool = hl.get("cleanse", false) and Status.cleanse(v)
			_refresh_unit(v)
			fx.on_heal(id, u, v, amount, cured)
			await _popup(v, ("+%d" % amount) + ("\nGegengift" if cured else ""), Color(0.4, 1, 0.5))
		else:
			var dmg := Combat.damage(u, v, _cover_for(v, v["pos"]), 0.0, float(dm["mult"]) * pct, float(dm.get("ignore_def", 0.0)))
			fx.reflect_hit(v)
			await _deal(v, dmg, "")
	if healing:
		_note("heal", {"by": u, "healed": victims})
	if first:
		_super_music_stop()
	_check_end()


## Das noch nicht ausgeloeste Geheimnis, das u mit Faehigkeit id auf den Verbuendeten o ausloest, oder {}.
func _secret_for(u: Dictionary, id: String, o: Dictionary) -> Dictionary:
	var sec := Secrets.find(u["id"], id, o["id"])
	if sec.is_empty() or secrets_done.has(sec["id"]):
		return {}
	return sec


## Geheime Interaktion: Fass trifft den Verbuendeten, beim ersten Mal laeuft die Szene, dann Bonus und neue Faehigkeit.
func _run_secret(u: Dictionary, id: String, target: Dictionary) -> void:
	var sec := _secret_for(u, id, target)
	var ab: Dictionary = abilities[id]
	u["st"]["abs"] += 1
	Items.start_cooldown(u, id, int(ab["cd"]))
	_actor = u
	_note("ability", {"id": id, "by": u})
	_turn_towards(u, target["pos"])
	if sec.is_empty():
		return
	secrets_done.append(sec["id"])
	if fx.has_fx(id):
		_banner(ab["name"])
	await fx.windup(id, u, target)
	await fx.before_hit(id, u, target, 0)
	fx.on_hit(id, u, target, 0)
	await get_tree().create_timer(0.5).timeout
	if not secrets_seen.has(sec["id"]):
		secrets_seen.append(sec["id"])
		if secret_runner.is_valid():
			await secret_runner.call(sec)
	var ef: Dictionary = sec["effects"]
	var pct := float(ef.get("atk_pct", 0))
	var mods := {}
	if pct > 0.0:
		mods = {"atk": maxi(1, roundi(float(target["atk"]) * pct / 100.0))}
	Status.add(target, str(ef.get("status", "betrunken")), 99, mods)
	var gift: String = ef.get("grant_ability", "")
	if gift != "" and not (target["abilities"] as Array).has(gift):
		(target["abilities"] as Array).append(gift)
	_refresh_unit(target)
	await fx.secret_reveal(target, sec)
	_popup(target, sec["name"] + "!", Color(1.0, 0.85, 0.4))
	if gift != "":
		await get_tree().create_timer(0.35).timeout
		await _popup(target, "Neu: " + abilities[gift]["name"], Color(0.75, 1.0, 0.6))
	_check_end()


func _area_tiles(ab: Dictionary, center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Dictionary = ab.get("area", {})
	if a.is_empty():
		return out
	var r: int = a.get("r", 1)
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var p := center + Vector2i(dx, dy)
			if not grid.inside(p):
				continue
			if a["shape"] == "radius" and absi(dx) + absi(dy) <= r:
				out.append(p)
			elif a["shape"] == "ring8" and maxi(absi(dx), absi(dy)) == 1:
				out.append(p)
	return out


## Felder einer geraden Linie vom Ursprung in Richtung to (bis rmax Felder).
func _line_tiles(origin: Vector2i, to: Vector2i, rmax: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var d := Vector2i(signi(to.x - origin.x), signi(to.y - origin.y))
	for k in range(1, rmax + 1):
		var p := origin + d * k
		if grid.inside(p):
			out.append(p)
	return out


func _begin_ability(id: String) -> void:
	_close_menu()
	_target_kind = "ability"
	_cur_ab = id
	_target_units = _ab_targets(sel, id, sel["pos"])
	_target_objs = _obj_targets(sel, id, sel["pos"])
	if abilities[id]["target"] == "tile":
		_target_kind = "ability_tile"
		_landing_tiles = _ab_tiles(sel, id, sel["pos"])
		var tt := {sel["pos"]: COL_SELF}
		for p in _landing_tiles:
			tt[p] = Color(1.0, 0.82, 0.25, 0.45)
		_show_tiles(tt)
		_hint.text = "%s: Zielfeld wählen. Rechtsklick = zurück." % abilities[id]["name"]
	else:
		_show_ability_tiles(sel["pos"])
	state = State.TARGETING
	_update_status()


## Markiert gueltige Ziele (rot/gruen) und die Wirkungsflaeche (orange) um center.
func _show_ability_tiles(center: Vector2i) -> void:
	var ab: Dictionary = abilities[_cur_ab]
	var tiles := {}
	if ab.get("shape", "") == "line":
		if center != sel["pos"]:
			for p in _line_tiles(sel["pos"], center, int(ab["range"][1])):
				tiles[p] = Color(1.0, 0.6, 0.15, 0.4)
	else:
		for p in _area_tiles(ab, sel["pos"] if ab["target"] == "self" else center):
			tiles[p] = Color(1.0, 0.6, 0.15, 0.4)
	for o in _target_units:
		tiles[o["pos"]] = COL_ATTACK if o["team"] != sel["team"] else COL_HEAL
	for wo in _target_objs:
		tiles[wo["pos"]] = Color(1.0, 0.82, 0.25, 0.6)
	tiles[sel["pos"]] = COL_SELF
	_show_tiles(tiles)


func _effect_targets(u: Dictionary, ab: Dictionary, target: Dictionary, to: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match to:
		"target":
			if units.has(target):
				out.append(target)
		"self":
			out.append(u)
		"line_enemies":
			var d := Vector2i(signi(target["pos"].x - u["pos"].x), signi(target["pos"].y - u["pos"].y))
			for k in range(1, int(ab["range"][1]) + 1):
				var o := unit_at(u["pos"] + d * k)
				if not o.is_empty() and o["team"] != u["team"] and _hittable(o) and not Status.has(o, "stealth"):
					out.append(o)
		"area_enemies", "area_allies":
			var center: Vector2i = u["pos"] if ab["target"] == "self" else target["pos"]
			var tiles := _area_tiles(ab, center)
			for o in units:
				if not tiles.has(o["pos"]):
					continue
				var enemy: bool = o["team"] != u["team"]
				if (to == "area_enemies" and enemy and _hittable(o) and not Status.has(o, "stealth")) or (to == "area_allies" and not enemy):
					out.append(o)
	return out


func _run_ability(u: Dictionary, id: String, target: Dictionary) -> void:
	var ab: Dictionary = abilities[id]
	if ab["target"] == "enemy" and target.get("team", "") == u["team"] and target != u:
		await _run_secret(u, id, target)
		return
	var bb := _beam_blocker(u, id, target)
	var catch_bb := {}
	if not bb.is_empty():
		if str(bb["sec"]["effects"].get("mode", "reflect")) == "reflect":
			await _run_reflect(u, id, target, bb["via"], bb["sec"])
			return
		catch_bb = bb          # "catch": der Angriff laeuft normal weiter, die Figur im Weg faengt etwas auf
	u["st"]["abs"] += 1
	Items.start_cooldown(u, id, int(ab["cd"]))
	_actor = u
	_note("ability", {"id": id, "by": u})
	if target != u:
		_turn_towards(u, target["pos"])
	if ab.get("super", false):
		await _super_cutin(u, ab)
	if fx.has_fx(id):
		_banner(ab["name"])   # Name blendet parallel zur Animation ein
	else:
		_banner(ab["name"])
		await get_tree().create_timer(0.4).timeout
	await fx.windup(id, u, target)
	if not catch_bb.is_empty():
		await _run_catch(u, catch_bb["via"], catch_bb["sec"])
	var tiles := _area_tiles(ab, u["pos"] if ab["target"] == "self" else target["pos"])
	await fx.cast(id, u, target, tiles)
	for ef: Dictionary in ab["effects"]:
		if not units.has(u):
			break
		await _apply_effect(u, ab, target, ef)
	await fx.after(id, u, target)
	_refresh_unit(u)
	if ab.get("super", false):
		_super_music_stop()
	_check_end()


func _apply_effect(u: Dictionary, ab: Dictionary, target: Dictionary, ef: Dictionary) -> void:
	var victims := _effect_targets(u, ab, target, ef.get("to", "target"))
	match ef["type"]:
		"damage":
			var first := true
			var hits: int = ef.get("hits", 1)
			var own_fx: bool = fx.has_fx(ab["id"])
			for v in victims:
				for h in hits:
					if not units.has(v):
						break
					await fx.before_hit(ab["id"], u, v, h)
					fx.on_hit(ab["id"], u, v, h)
					var last_victim: bool = v == victims[victims.size() - 1]
					await _strike(u, v, ef["mult"], ef.get("ignore_def", 0.0), first and not own_fx, (hits > 1 and h < hits - 1) or (victims.size() > 1 and not last_victim))
					first = false
		"splash":
			var near := units.filter(func(o: Dictionary) -> bool:
				return o["team"] != u["team"] and _hittable(o) and o != target and Grid.dist(o["pos"], target["pos"]) == 1)
			for v in near:
				fx.on_splash(ab["id"], u, v)
				await _strike(u, v, ef["mult"], 0.0, false)
		"summon_hive":
			var hive := world.add_object("hive_p", target["pos"], {"owner": u["uid"]})
			grid.blocked = world.blocked()
			_make_object(hive)
			_refresh_object(hive, true)
			await fx.hive_appear(u, to_world(target["pos"]))
		"vanish":
			await _vanish(u, ef)
		"assassinate":
			if units.has(target):
				if _is_normal(target):
					await fx.assassinate(u, target)
					await _deal(target, target["hp"], "Hinterhalt")
				else:
					await _strike(u, target, ef["mult"], 0.0, true)
		"status":
			if ef.has("chance"):
				var kept: Array[Dictionary] = []
				for v in victims:
					if rng.randf() < float(ef["chance"]):
						kept.append(v)
				if kept.is_empty() and not victims.is_empty():
					kept.append(victims[rng.randi() % victims.size()])
				victims = kept
			for v in victims:
				var src: String = u["uid"] if ef["id"] == "taunt" else ""
				Status.add(v, ef["id"], ef["turns"], ef.get("mods", {}), src)
				_refresh_unit(v)
				var good: bool = Status.GOOD.has(ef["id"])
				if fx.has_fx(ab["id"]):
					await fx.on_status(ab["id"], u, v, ef["id"])
				else:
					await _popup(v, Status.NAMES[ef["id"]], Color(0.5, 1, 0.6) if good else Color(1, 0.7, 0.3))
		"heal":
			var healed: Array[Dictionary] = []
			for v in victims:
				var amount := mini(ef["amount"], v["maxhp"] - v["hp"])
				if amount > 0 or Status.has(v, "poison"):
					healed.append(v)
				v["hp"] += amount
				u["st"]["healed"] += amount
				var cured: bool = ef.get("cleanse", false) and Status.cleanse(v)
				_refresh_unit(v)
				fx.on_heal(ab["id"], u, v, amount, cured)
				await _popup(v, ("+%d" % amount) + ("\nGegengift" if cured else ""), Color(0.4, 1, 0.5))
			_note("heal", {"by": u, "healed": healed})
		"jump":
			if units.has(target):
				var land: Vector2i = target["pos"] + (target["pos"] - u["pos"])
				if fx.has_fx(ab["id"]):
					await fx.jump_anim(u, target, land)
				else:
					await _arc_move(u, land)
				_turn_towards(u, target["pos"])
		"throw":
			if units.has(target):
				await _throw(u, target, ef)
		"polymorph":
			if units.has(target):
				Status.add(target, "polymorph", ef["turns"])
				units.erase(target)
				_away.append(target)
				if fx.has_fx(ab["id"]):
					await fx.polymorph_out(u, target)
				else:
					await _popup(target, "Quak!", Color(0.6, 1, 0.5))
				(target["node"] as Node3D).visible = false


## Hupfbewegung auf ein Feld (Stabsprung, Wurf).
func _arc_move(u: Dictionary, dest: Vector2i, height := 0.9) -> void:
	var n: Node3D = u["node"]
	var from := n.position
	var to := to_world(dest)
	u["pos"] = dest
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		n.position = from.lerp(to, t) + Vector3(0, sin(t * PI) * height, 0), 0.0, 1.0, 0.45)
	await tw.finished


## Muskelaugust: bis zu ef["dist"] Felder in eine zufaellige gueltige Richtung.
func _throw(u: Dictionary, target: Dictionary, ef: Dictionary) -> void:
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var valid_dirs: Array = []
	var landings: Array[Vector2i] = []
	for d in dirs:
		var land := Vector2i(-1, -1)
		for steps in range(int(ef["dist"]), 0, -1):   # weitester gueltiger Landepunkt; die Flugbahn selbst ist egal
			var p: Vector2i = target["pos"] + d * steps
			if _tile_free(p, target):
				land = p
				break
		valid_dirs.append(land.x >= 0)
		landings.append(land)
	var usable: Array[int] = []
	for i in 4:
		if valid_dirs[i]:
			usable.append(i)
	var dir_idx := -1
	var chosen: Vector2i = target["pos"]
	if not usable.is_empty():
		dir_idx = usable[rng.randi() % usable.size()]
		chosen = landings[dir_idx]
	if fx.has_fx("wurf"):
		await fx.throw_anim(u, target, valid_dirs, dir_idx, chosen)
	elif chosen != target["pos"]:
		await _arc_move(target, chosen, 1.6)
	var dmg := Combat.damage(u, target, _cover_for(target, target["pos"]), 0.0, ef["mult"])
	await _deal(target, dmg, "Aufprall")
	if units.has(target):
		Status.add(target, "stun", ef["stun"])
		_refresh_unit(target)
		await _popup(target, "Benommen", Color(1, 0.7, 0.3))


## Schaden ohne Angriff (Aufprall, Gift ...).
func _deal(def: Dictionary, dmg: int, text: String) -> void:
	_count(_actor, def, mini(dmg, def["hp"]))
	def["hp"] = maxi(0, def["hp"] - dmg)
	_refresh_unit(def)
	await _popup(def, ("-%d" % dmg) + (("\n" + text) if text != "" else ""), Color(1, 0.45, 0.35))
	if def["hp"] <= 0:
		units.erase(def)
		await _down(def)


func _free_tile_near(p: Vector2i, mover: Dictionary) -> Vector2i:
	var seen := {p: true}
	var queue: Array[Vector2i] = [p]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if _tile_free(cur, mover):
			return cur
		for d in Grid.DIRS:
			var n: Vector2i = cur + d
			if grid.inside(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return p


func _return_from_polymorph(u: Dictionary) -> void:
	_away.erase(u)
	u["pos"] = _free_tile_near(u["pos"], u)
	units.append(u)
	var n: Node3D = u["node"]
	n.position = to_world(u["pos"])
	if fx.has_fx("polymorph"):
		await fx.polymorph_in(u)
	n.visible = true
	_refresh_unit(u)
	await _popup(u, "Zurück!", Color(0.6, 1, 0.5))


# ------------------------------------------------------------------ Phasen

## Beginn der Phase eines Teams: Gift tickt, Status laufen ab, Abklingzeiten sinken, Benommene setzen aus.
func _begin_phase(team: String) -> void:
	if team == "p":
		Sfx.event("turn_start")
		await _retie_check()
	for u in (units + _away):
		if u["team"] != team:
			continue
		u["done"] = false
		u["charge"] = 0
		var stunned := Status.has(u, "stun")
		for ev: Dictionary in Status.tick_phase_start(u):
			if ev["type"] == "poison" or ev["type"] == "burn":
				_count({}, u, mini(int(ev["amount"]), u["hp"]))
				u["hp"] = maxi(0, u["hp"] - ev["amount"])
				_refresh_unit(u)
				await _popup(u, "-%d %s" % [ev["amount"], "Gift" if ev["type"] == "poison" else "Brand"], Color(0.6, 1.0, 0.4) if ev["type"] == "poison" else Color(1.0, 0.6, 0.2))
				if u["hp"] <= 0:
					units.erase(u)
					_away.erase(u)
					await _down(u)
					break
			elif ev["type"] == "expire" and ev["id"] == "polymorph":
				await _return_from_polymorph(u)
		if units.has(u) and not u["flying"] and world.burning_tiles().has(u["pos"]):
			await _burn(u)
		if units.has(u):
			if stunned:
				u["done"] = true
			_refresh_unit(u)
	_check_end()
	if state != State.OVER:
		await _flush_events()


func _end_player_turn() -> void:
	if state == State.BUSY or state == State.OVER:
		return
	state = State.BUSY
	sel = {}
	_close_menu()
	_show_tiles({})
	_show_card({})
	_update_status()
	_status.text = "Runde %d  –  Gegnerphase" % turn
	await _capture_phase()
	if state == State.OVER:
		return
	await _begin_phase("e")
	if state == State.OVER:
		return
	await _fire_phase()
	if state == State.OVER:
		return
	await _hive_phase()
	for e in units.filter(func(u: Dictionary) -> bool: return u["team"] == "e"):
		if not units.has(e) or e["done"]:
			continue
		if e["guard"] and not _alarm(e):
			continue
		await _enemy_move(e)
		if units.has(e):
			await _sting_check(e)
		if state == State.OVER:
			return
	turn += 1
	await _begin_phase("p")
	if state == State.OVER:
		return
	await _run_triggers("turn", turn)
	await _run_scheduled()
	await _player_hive_phase()
	await _rage_phase()
	_check_end()
	if state == State.OVER:
		return
	state = State.IDLE
	_update_status()
	if _all_done("p"):
		_end_player_turn()


## Wachen ruehren sich nicht, bis ein (sichtbarer) Held auf GUARD_RADIUS Felder herankommt, danach kaempfen sie normal.
const GUARD_RADIUS := 3

func _alarm(e: Dictionary) -> bool:
	for u in units:
		if u["team"] == "p" and not Status.has(u, "stealth") and Grid.dist(u["pos"], e["pos"]) <= GUARD_RADIUS:
			e["guard"] = false
			return true
	return false


func _run_scheduled() -> void:
	for s: Dictionary in _scheduled.filter(func(x: Dictionary) -> bool: return x["turn"] <= turn):
		_scheduled.erase(s)
		for t: Dictionary in triggers:
			if t.get("id", "") == s["id"] and not t.get("fired", false):
				t["fired"] = true
				await _fire(t)


const HIVE_CAP := 6      # so viele Bienenkrieger gleichzeitig, hoechstens (Messung: docs/balance.md, Mission 5)

## Bienenstoecke: alle 2 Gegnerphasen schluepft ein Bienenkrieger (hoechstens HIVE_CAP gleichzeitig).
func _hive_phase() -> void:
	for o in world.objects:
		if o["type"] != "hive" or o["state"] != "active":
			continue
		o["clock"] = int(o.get("clock", 0)) + 1
		var alive := units.filter(func(u: Dictionary) -> bool: return u["id"] == "bienenkrieger").size()
		if int(o["clock"]) % 2 != 0 or alive >= HIVE_CAP:
			continue
		var pos := _free_tile_near(o["pos"], {"flying": true})
		_spawn("bienenkrieger", "e", pos, {})
		Sfx.event("buzz")
		await _popup(units.back(), "Bzzz!", Color(1.0, 0.85, 0.3))


## Bienen am Waisenhaus: jede stoert die Kinder (Bonusziel "Kein Kind gestochen").
func _sting_check(e: Dictionary) -> void:
	if not (e["tags"] as Array).has("schwarm") and e["id"] != "bienenmaedchen":
		return
	for o in world.objects:
		if o["type"] == "orphanage" and Grid.dist(e["pos"], o["pos"]) == 1:
			kids_stung += 1
			await _popup({"pos": o["pos"]}, "Autsch! Die Kinder werden gestochen", Color(1.0, 0.5, 0.4))
			return


func _taunter(e: Dictionary) -> Dictionary:
	var st := Status.get_status(e, "taunt")
	if st.is_empty():
		return {}
	for u in units:
		if u["uid"] == st["src"]:
			return u
	return {}


## Verwundete Verbuendete versorgen (Priester). true = hat geheilt.
func _enemy_heal(e: Dictionary, reach_e: Dictionary, occupied: Dictionary) -> bool:
	var best := -INF
	var best_t := Vector2i.ZERO
	var best_a: Dictionary = {}
	for a in units:
		if a == e or a["team"] != e["team"] or not (a["hp"] < a["maxhp"] or Status.has(a, "poison")):
			continue
		for t: Vector2i in reach_e:
			if occupied.has(t) or not Combat.in_range(e, Grid.dist(t, a["pos"])):
				continue
			var score: float = (a["maxhp"] - a["hp"]) + (8.0 if Status.has(a, "poison") else 0.0) - Grid.dist(e["pos"], t) * 0.1
			if score > best:
				best = score
				best_t = t
				best_a = a
	if best_a.is_empty():
		return false
	reach = reach_e
	await _walk(e, best_t)
	await _resolve(e, best_a)
	await get_tree().create_timer(0.15).timeout
	return true


## Faehigkeiten auf sich selbst (Befehl, Einschuechtern) setzt die Gegner-KI ein, wenn genug Ziele im Umkreis sind.
func _enemy_self_ability(e: Dictionary) -> String:
	for id: String in e["abilities"]:
		var ab: Dictionary = abilities[id]
		if ab["target"] != "self" or not ab.has("ai_self") or int(e["cd"].get(id, 0)) > 0:
			continue
		var tiles := _area_tiles(ab, e["pos"])
		var n_allies := 0
		var n_foes := 0
		for o in units:
			if o == e or not tiles.has(o["pos"]):
				continue
			if o["team"] == e["team"]:
				n_allies += 1
			elif not Status.has(o, "stealth"):
				n_foes += 1
		if n_allies >= int(ab["ai_self"].get("allies", 999)) or n_foes >= int(ab["ai_self"].get("enemies", 999)):
			return id
	return ""


## Eingeschuechterte Gegner laufen vom naechsten Helden weg und greifen nicht an.
func _flee_scared(e: Dictionary, reach_e: Dictionary, occupied: Dictionary) -> void:
	var foes := units.filter(func(u: Dictionary) -> bool: return u["team"] != e["team"])
	if foes.is_empty():
		return
	var best_t: Vector2i = e["pos"]
	var best_d := -1.0
	for t: Vector2i in reach_e:
		if occupied.has(t) and t != e["pos"]:
			continue
		var dmin := 999.0
		for f in foes:
			dmin = minf(dmin, float(Grid.dist(t, f["pos"])))
		if dmin > best_d:
			best_d = dmin
			best_t = t
	reach = reach_e
	await fx.scared_shiver(e)
	await _walk(e, best_t)
	await _flush_events()


## Normale Gegner (Soldaten, Bienen) sterben beim Hinterhalt sofort; Namenstraeger und Bosse nicht.
func _is_normal(o: Dictionary) -> bool:
	var tags: Array = o["tags"]
	return tags.has("standard") or tags.has("schwarm")


## Bienenkorb der Stachelia: alle 2 Runden schluepft eine Biene (hoechstens 3), nach 6 Runden loest er sich auf.
const HIVE_P_CAP := 3
const HIVE_P_LIFE := 6

func _player_hive_phase() -> void:
	for o in world.objects.duplicate():
		if o["type"] != "hive_p" or o["state"] != "active":
			continue
		o["age"] = int(o["age"]) + 1
		if int(o["age"]) >= HIVE_P_LIFE:
			o["state"] = "gone"
			grid.blocked = world.blocked()
			_refresh_object(o, true)
			fx.particles("fx_smoke", to_world(o["pos"]) + Vector3(0, 0.4, 0), 10, 1.5, 0.6, 0.9, -0.3, Color(0.8, 0.7, 0.4), false, 70.0)
			continue
		var alive := units.filter(func(u: Dictionary) -> bool: return u["id"] == "bienenkrieger" and u["team"] == "p").size()
		if int(o["age"]) % 2 != 0 or alive >= HIVE_P_CAP:
			continue
		var pos := _free_tile_near(o["pos"], {"flying": true})
		_spawn("bienenkrieger", "p", pos, {})
		Sfx.event("buzz")
		await _popup(units.back(), "Bzzz!", Color(1.0, 0.85, 0.3))


## Wutanfall: betroffene Helden handeln selbst (zufaelliges Ziel in Reichweite, auch Freunde).
func _rage_phase() -> void:
	for u in units.filter(func(x: Dictionary) -> bool: return x["team"] == "p" and Status.has(x, "wut") and not x["done"]):
		if not units.has(u):
			continue
		await _rage_act(u)
		if units.has(u):
			u["done"] = true
			_refresh_unit(u)
		_check_end()
		if state == State.OVER:
			return


func _rage_act(u: Dictionary) -> void:
	var reach_u := grid.reachable(u["pos"], Combat.move_of(u), u["flying"], _team_tiles("e"))
	var others: Array[Dictionary] = []
	var occupied := {}
	for o in units:
		if o != u:
			occupied[o["pos"]] = true
			if not Status.has(o, "stealth"):
				others.append(o)
	var opts: Array = []
	for t: Vector2i in reach_u:
		if occupied.has(t):
			continue
		for o in others:
			if Combat.in_range(u, Grid.dist(t, o["pos"])):
				opts.append([t, o])
	reach = reach_u
	fx.rage_burst(u)
	await _popup(u, "Arrr!", Color(1.0, 0.35, 0.25))
	if opts.is_empty():
		if others.is_empty():
			return
		var goal: Vector2i = others[rng.randi() % others.size()]["pos"]
		var best_t: Vector2i = u["pos"]
		var best_d := 9999
		for t: Vector2i in reach_u:
			if not occupied.has(t) and Grid.dist(t, goal) < best_d:
				best_d = Grid.dist(t, goal)
				best_t = t
		await _walk(u, best_t)
		return
	var pick: Array = opts[rng.randi() % opts.size()]
	await _walk(u, pick[0])
	await _strike(u, pick[1])
	if units.has(pick[1]) and pick[1]["hp"] > 0 and Combat.can_counter(pick[1], Grid.dist(u["pos"], pick[1]["pos"])):
		await _strike(pick[1], u)


## Maja (und wer sonst Rauch wirft): weg an einen freien Randfeld, danach etwas erholt.
func _vanish(u: Dictionary, ef: Dictionary) -> void:
	var edge: Array[Vector2i] = []
	for y in grid.height:
		for x in grid.width:
			if x == 0 or y == 0 or x == grid.width - 1 or y == grid.height - 1:
				var p := Vector2i(x, y)
				if _tile_free(p, u) and world.at(p).is_empty() and Grid.dist(p, u["pos"]) > 2:
					edge.append(p)
	await fx.vanish_out(u)
	if not edge.is_empty():
		var dest: Vector2i = edge[rng.randi() % edge.size()]
		u["pos"] = dest
		(u["node"] as Node3D).position = to_world(dest)
	var gain := mini(roundi(float(ef.get("heal_pct", 0.2)) * u["maxhp"]), u["maxhp"] - u["hp"])
	u["hp"] += gain
	_refresh_unit(u)
	await fx.vanish_in(u)
	if gain > 0:
		await _popup(u, "+%d" % gain, Color(0.4, 1, 0.5))


func _enemy_move(e: Dictionary) -> void:
	for id: String in e["abilities"]:      # Maja: bei schwerer Verletzung Rauch und weg (einmal pro Kampf)
		var fab: Dictionary = abilities[id]
		if fab.has("ai_flee") and int(e["cd"].get(id, 0)) == 0 and float(e["hp"]) <= float(fab["ai_flee"]) * e["maxhp"]:
			await _run_ability(e, id, e)
			await _flush_events()
			return
	var reach_e := grid.reachable(e["pos"], Combat.move_of(e), e["flying"], _team_tiles("p"))
	var occupied := {}
	for o in units:
		if o != e:
			occupied[o["pos"]] = true
	if not e["flying"]:
		for ft: Vector2i in world.burning_tiles():
			if ft != e["pos"]:
				occupied[ft] = true      # kein Ziel-/Standfeld im Feuer
	if Status.has(e, "angst"):
		await _flee_scared(e, reach_e, occupied)
		return
	if e["heal"] > 0 and await _enemy_heal(e, reach_e, occupied):
		return
	var players := units.filter(func(u: Dictionary) -> bool: return u["team"] == "p" and not Status.has(u, "stealth"))
	var forced := _taunter(e)
	if not forced.is_empty():
		players = [forced]   # Spott: nur dieses Ziel zaehlt
	var usable: Array[String] = []
	for id: String in e["abilities"]:
		var ab: Dictionary = abilities[id]
		if e["cd"].get(id, 0) == 0 and ab["target"] == "enemy" and ab.has("ai_bonus") and not _first_effect(ab, "damage").is_empty():
			usable.append(id)
	var best_score := -INF
	var best_tile: Vector2i = e["pos"]
	var best_target: Dictionary = {}
	var best_ab := ""
	for t: Vector2i in reach_e:
		if occupied.has(t):
			continue
		for p in players:
			var dd := Grid.dist(t, p["pos"])
			var spread := minf(float(dd), 3.0) * 0.3 if e["range_min"] > 1 else 0.0   # Fernkaempfer halten Abstand
			if Combat.in_range(e, dd):
				var fc := forecast(e, p, t)
				var score: float = fc["dmg"] * 10.0 + (60.0 if fc["kill"] else 0.0) + grid.def_bonus(t) * 3.0 \
					- maxf(fc["counter"], 0.0) * 2.0 - Grid.dist(e["pos"], t) * 0.1 + spread
				if score > best_score:
					best_score = score
					best_tile = t
					best_target = p
					best_ab = ""
			for id in usable:
				var ab: Dictionary = abilities[id]
				var r: Array = ab["range"]
				if dd < r[0] or dd > r[1]:
					continue
				var dm := _first_effect(ab, "damage")
				var fc := forecast(e, p, t, dm["mult"], dm.get("ignore_def", 0.0))
				var score: float = fc["dmg"] * dm.get("hits", 1) * 10.0 + float(ab["ai_bonus"]) + (60.0 if fc["kill"] else 0.0) \
					+ grid.def_bonus(t) * 3.0 - Grid.dist(e["pos"], t) * 0.1 + spread
				if score > best_score:
					best_score = score
					best_tile = t
					best_target = p
					best_ab = id
	if best_target.is_empty():
		# Kein Ziel in Reichweite: auf den naechsten sichtbaren Spieler zulaufen.
		var best_d := 9999.0
		var goals: Array = players.map(func(u: Dictionary) -> Vector2i: return u["pos"])
		if (e["tags"] as Array).has("schwarm"):
			for o in world.objects:
				if o["type"] == "orphanage":
					goals = [o["pos"]]       # der Schwarm geht aufs Waisenhaus, wenn kein Held erreichbar ist
		for t: Vector2i in reach_e:
			if occupied.has(t):
				continue
			for gp: Vector2i in goals:
				var dd := Grid.dist(t, gp) - grid.def_bonus(t) * 0.1
				if dd < best_d:
					best_d = dd
					best_tile = t
	reach = reach_e
	await _walk(e, best_tile)
	var sid := _enemy_self_ability(e)
	if sid != "":
		await _run_ability(e, sid, e)
		await _flush_events()
		return
	if not best_target.is_empty():
		if best_ab != "":
			await _run_ability(e, best_ab, best_target)
		else:
			await _resolve(e, best_target)
	await _flush_events()
	await get_tree().create_timer(0.15).timeout