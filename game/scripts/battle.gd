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
var fallen: Array[String] = []         # gefallene Helden (fuer Bonusziele)
var _start_inventory: Dictionary = {}
var _results: Dictionary = {}
var goal: Dictionary = {"type": "rout"}
var triggers: Array = []                 # {when, do, fired}
var _notes: Array = []                    # Ereignisse seit der letzten Pruefung: {kind, ...}
var kills_total := 0                      # besiegte Gegner insgesamt
var _actor: Dictionary = {}               # zuletzt handelnde Figur (fuer "$hero" bei Ereignissen ohne eigenen Ausloeser)
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
	_start_inventory = inventory.duplicate()
	for k: String in abilities:
		abilities[k]["id"] = k
	grid = Grid.new(map_data["rows"])
	world = World.new(map_data.get("objects", []))
	grid.blocked = world.blocked()
	terrain = TerrainView.new()
	terrain.setup(grid)
	add_child(terrain)
	_build_environment()
	fx = Fx.new()
	add_child(fx)
	fx.setup(self)
	_build_loot()
	_build_objects()
	for fy in grid.height:
		for fx_ in grid.width:
			if grid.terrain(Vector2i(fx_, fy)) == "F":
				_flammable[Vector2i(fx_, fy)] = true
	_fire_preview = Node3D.new()
	add_child(_fire_preview)
	_update_fire_preview()
	goal = (map_data.get("goals", [{"type": "rout"}]) as Array)[0]
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
		_spawn(e["id"], "e", Vector2i(e["pos"][0], e["pos"][1]), {"carry": e.get("carry", {})})
	_build_hud()
	_update_status()


# ---------------------------------------------------------------- Darstellung

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
	}
	_next_uid += 1
	u["carry"] = extra.get("carry", {})
	if team == "p":
		Items.apply_equipment(u, (loadout.get("equipment", {}) as Dictionary).get(id, []))
	var node := Node3D.new()
	node.position = to_world(pos)
	add_child(node)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.33
	ring.bottom_radius = 0.33
	ring.height = 0.05
	_mesh(ring, TEAM_COLOR[team], Vector3(0, 0.03, 0), node)
	var lift := 0.35 if u["flying"] else 0.0
	var tex := _portrait_tex(d.get("portrait", id))
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = 1.35 / maxf(tex.get_width(), tex.get_height())
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
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font = UiTheme.font(UiTheme.F_TITLE)
	lbl.font_size = 48
	lbl.pixel_size = 0.006
	lbl.outline_size = 14
	lbl.no_depth_test = true
	lbl.modulate = TEAM_COLOR[team].lerp(Color.WHITE, 0.5)
	lbl.position = Vector3(0, 1.9 + lift, 0)
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


func _refresh_unit(u: Dictionary) -> void:
	var st := Status.label(u)
	(u["label"] as Label3D).text = "%d" % u["hp"] + ("\n" + st if st != "" else "")
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
	_status.text = "Runde %d  –  %s" % [turn, "Deine Phase" if state != State.BUSY else "Gegner / Aktion"]
	_goal.text = Mission.goal_text(goal, _count_team("e"), turn)
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
	for u in units:
		(u["label"] as Label3D).visible = false


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
		(u["label"] as Label3D).visible = true
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


func _pick_tile(screen: Vector2) -> Vector2i:
	return terrain.pick(cam.project_ray_origin(screen), cam.project_ray_normal(screen))


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


func _attack_targets(u: Dictionary, pos: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in units:
		if o["team"] != u["team"] and not Status.has(o, "stealth") and Combat.in_range(u, Grid.dist(pos, o["pos"])):
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
	_show_card(u if not u.is_empty() else sel)
	if state == State.TARGETING and not u.is_empty() and _target_units.has(u):
		_forecast.text = _forecast_text(sel, u)
		if _target_kind == "ability" and (abilities[_cur_ab]["target"] == "ally_center" or abilities[_cur_ab].get("shape", "") == "line"):
			_show_ability_tiles(u["pos"])
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
				_cancel()
		State.TARGETING:
			if _target_kind == "landing":
				if _landing_tiles.has(p):
					_do_throw_ally(p)
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
	reach = grid.reachable(u["pos"], u["move"], u["flying"], blocked)
	var occupied := {}
	for o in units:
		if o != u:
			occupied[o["pos"]] = true
	var tiles := {}
	for p: Vector2i in reach:
		if not occupied.has(p):
			tiles[p] = COL_MOVE
	for p: Vector2i in occupied.keys():
		reach.erase(p)
	reach[u["pos"]] = 0
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
			var ok := cd == 0 and (not _ab_targets(sel, id, sel["pos"]).is_empty() or not _obj_targets(sel, id, sel["pos"]).is_empty())
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
			var hs := _hostage_near(sel["pos"])
			if not hs.is_empty():
				_menu_button(box, "Befreien", true, func() -> void: _free_hostage(sel, hs))
			var vl := _village_at(sel["pos"])
			if not vl.is_empty() and not vl["visited"]:
				_menu_button(box, "Dorf besuchen", true, func() -> void: _collect(sel, vl, "village"))
		_menu_button(box, "Verteidigen", true, func() -> void: _defend(sel))
		_menu_button(box, "Warten", true, func() -> void:
			_close_menu()
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
		var entry := {"pos": pos, "reward": c["reward"], "open": false, "node": null, "lid": null}
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
	var wood := Color(0.45, 0.28, 0.14)
	var dark := Color(0.30, 0.18, 0.09)
	var iron := Color(0.42, 0.42, 0.48)
	var gold := Color(0.95, 0.78, 0.25)
	var body := MeshKit.new()
	body.box(Vector3(0, 0.13, 0), Vector3(0.46, 0.26, 0.3), wood)
	body.box(Vector3(-0.15, 0.13, 0), Vector3(0.05, 0.27, 0.31), iron)
	body.box(Vector3(0.15, 0.13, 0), Vector3(0.05, 0.27, 0.31), iron)
	var lid := MeshKit.new()
	lid.box(Vector3(0, 0.05, 0), Vector3(0.48, 0.1, 0.32), dark)
	lid.box(Vector3(-0.15, 0.05, 0), Vector3(0.05, 0.11, 0.33), iron)
	lid.box(Vector3(0.15, 0.05, 0), Vector3(0.05, 0.11, 0.33), iron)
	lid.box(Vector3(0, 0.0, 0.17), Vector3(0.07, 0.1, 0.03), gold)
	var root := Node3D.new()
	root.position = to_world(entry["pos"]) + Vector3(0, 0.02, 0)
	root.rotation.y = 0.35
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var bi := MeshInstance3D.new()
	bi.mesh = body.build()
	bi.material_override = mat
	root.add_child(bi)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.26, -0.15)     # Scharnier hinten
	root.add_child(pivot)
	var li := MeshInstance3D.new()
	li.mesh = lid.build()
	li.material_override = mat
	li.position = Vector3(0, 0, 0.15)
	pivot.add_child(li)
	entry["node"] = root
	entry["lid"] = pivot


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
	m.position = Vector3(0.0, 2.45 + lift, 0)
	var sack := SphereMesh.new()
	sack.radius = 0.16
	sack.height = 0.3
	var sm := _mesh(sack, Color(0.62, 0.42, 0.22), Vector3.ZERO, m)
	sm.material_override = _unshaded_mat(Color(0.7, 0.48, 0.25))
	var tie := SphereMesh.new()
	tie.radius = 0.06
	tie.height = 0.12
	var tm := _mesh(tie, Color(1.0, 0.82, 0.25), Vector3(0, 0.18, 0), m)
	tm.material_override = _unshaded_mat(Color(1.0, 0.85, 0.3))
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
		var tw := create_tween()
		tw.tween_property(entry["lid"], "rotation_degrees:x", -105.0, 0.4).set_trans(Tween.TRANS_BACK)
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
	if def["team"] == "e" and unit_defs[def["id"]].get("flees", false):
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
	_results = gained
	return gained


# ------------------------------------------------------------------ Weltobjekte

func _build_objects() -> void:
	for o in world.objects:
		_make_object(o)
		_refresh_object(o, false)


func _make_object(o: Dictionary) -> void:
	if o["type"] == "fire" or o["type"] == "house":
		_make_burnable(o)
		return
	if o["type"] == "teahouse" or o["type"] == "hostage":
		_make_teahouse(o) if o["type"] == "teahouse" else _make_hostage(o)
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
		"switch":
			body.box(Vector3(0, 0.12, 0), Vector3(0.3, 0.24, 0.3), stone)
			body.box(Vector3(0, 0.26, 0), Vector3(0.36, 0.04, 0.36), dark)
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
	if o["type"] == "switch":
		var lp := Node3D.new()
		lp.position = Vector3(0, 0.27, 0)
		root.add_child(lp)
		var lever := MeshKit.new()
		lever.box(Vector3(0, 0.14, 0), Vector3(0.05, 0.28, 0.05), iron)
		lever.box(Vector3(0, 0.3, 0), Vector3(0.11, 0.11, 0.11), Color(0.85, 0.15, 0.15))
		var li := MeshInstance3D.new()
		li.mesh = lever.build()
		li.material_override = mat
		lp.add_child(li)
		parts["lever"] = lp
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
		"switch":
			if animate:
				Sfx.event("switch")
			p["rubble"].visible = false
			var lv: Node3D = p["lever"]
			var tilt := 35.0 if st == "on" else -35.0
			if animate:
				lv.create_tween().tween_property(lv, "rotation_degrees:z", tilt, 0.25).set_trans(Tween.TRANS_BACK)
			else:
				lv.rotation_degrees.z = tilt
		"hostage":
			if st == "free":
				if animate:
					Sfx.event("free")
				var sp: Sprite3D = p["sprite"]
				(p["body"] as Node3D).visible = false
				if animate:
					var rn: Node3D = p["root"]
					var run := rn.position + Vector3(0, 0, 4.0)
					var wtw := create_tween().set_parallel(true)
					wtw.tween_property(rn, "position", run, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					wtw.tween_property(sp, "modulate:a", 0.0, 1.4)
				else:
					sp.visible = false
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
			if animate:
				Sfx.event("fire" if st == "burning" else ("ruin" if st == "ruin" else "extinguish"))
			if animate and st == "burning":
				fx.light_flash(to_world(o["pos"]) + Vector3(0, 0.7, 0), Color(1.0, 0.6, 0.2), 2.5, 4.0, 0.6)
			elif animate and st == "intact":
				fx.particles("fx_foam", to_world(o["pos"]) + Vector3(0, 0.5, 0), 12, 3.0, 0.25, 0.7, 5.0, Color.WHITE, false, 120.0)
			elif animate and st == "ruin":
				fx.particles("fx_smoke", to_world(o["pos"]) + Vector3(0, 0.3, 0), 10, 1.5, 0.7, 1.0, -0.3, Color(0.3, 0.3, 0.3), false, 70.0)
	if not ["gate", "wall", "house"].has(o["type"]) and p["rubble"] != null:
		(p["rubble"] as Node3D).visible = false


## Teehaus: rote Saeulen, zwei geschwungene Daecher, goldene Spitze und Laternen. Nur Kulisse und gesperrtes Feld.
func _make_teahouse(o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	root.scale = Vector3.ONE * 1.3
	add_child(root)
	var k := MeshKit.new()
	var red := Color(0.62, 0.13, 0.1)
	var roof := Color(0.58, 0.14, 0.11)
	var cream := Color(0.93, 0.87, 0.7)
	var gold := Color(0.95, 0.78, 0.25)
	k.box(Vector3(0, 0.04, 0), Vector3(0.94, 0.08, 0.8), Color(0.52, 0.5, 0.47))
	k.box(Vector3(0, 0.27, 0), Vector3(0.62, 0.38, 0.5), cream)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			k.box(Vector3(sx * 0.33, 0.27, sz * 0.27), Vector3(0.06, 0.4, 0.06), red)
	k.box(Vector3(0, 0.22, 0.255), Vector3(0.16, 0.26, 0.02), Color(0.28, 0.17, 0.09))
	for wx in [-0.2, 0.2]:
		k.box(Vector3(wx, 0.3, 0.255), Vector3(0.12, 0.14, 0.02), Color(0.98, 0.84, 0.45))
	k.gable_roof(Vector3(0, 0.46, 0), Vector3(1.0, 0, 0.84), 0.16, roof)
	k.box(Vector3(0, 0.47, 0.0), Vector3(1.02, 0.03, 0.04), gold)
	k.box(Vector3(0, 0.55, 0), Vector3(0.36, 0.16, 0.3), cream)
	k.gable_roof(Vector3(0, 0.63, 0), Vector3(0.6, 0, 0.5), 0.13, roof)
	k.box(Vector3(0, 0.79, 0), Vector3(0.05, 0.14, 0.05), gold)
	for sx in [-1, 1]:
		k.box(Vector3(sx * 0.4, 0.36, 0.38), Vector3(0.08, 0.12, 0.08), red)
		k.box(Vector3(sx * 0.4, 0.43, 0.38), Vector3(0.1, 0.02, 0.1), gold)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = k.build()
	mi.material_override = mat
	root.add_child(mi)
	_obj_nodes[o["id"]] = {"root": root, "body": mi, "rubble": null, "doors": [], "lever": null}


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
	var k := MeshKit.new()
	var wood := Color(0.42, 0.26, 0.13)
	for sx in [-1, 1]:
		k.box(Vector3(sx * 0.3, 0.16, 0.1), Vector3(0.05, 0.32, 0.05), wood)
	k.box(Vector3(0, 0.12, 0.1), Vector3(0.62, 0.03, 0.03), Color(0.75, 0.65, 0.4))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = k.build()
	mi.material_override = mat
	root.add_child(mi)
	_obj_nodes[o["id"]] = {"root": root, "body": mi, "rubble": null, "doors": [], "lever": null, "sprite": sp}


## Haus (Fachwerk) oder Feuerfeld; Flammen sind Partikel mit warmem Schein, ein/aus je nach Zustand.
func _make_burnable(o: Dictionary) -> void:
	var root := Node3D.new()
	root.position = to_world(o["pos"])
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var parts := {"root": root, "body": Node3D.new(), "rubble": Node3D.new(), "doors": [], "lever": null, "flames": Node3D.new()}
	root.add_child(parts["body"])
	root.add_child(parts["rubble"])
	root.add_child(parts["flames"])
	var big: bool = o["type"] == "house"
	if big:
		var k := MeshKit.new()
		var h: int = (int(o["pos"].x) * 7 + int(o["pos"].y) * 13) % 3
		var roofs := [Color(0.62, 0.2, 0.14), Color(0.5, 0.28, 0.16), Color(0.7, 0.3, 0.18)]
		var walls := [Color(0.9, 0.84, 0.68), Color(0.86, 0.78, 0.6), Color(0.92, 0.88, 0.76)]
		terrain._house(k, Vector3.ZERO, Vector3(0.5, 0.3, 0.4), (h - 1) * 0.12, roofs[h], walls[h], 2 if h == 0 else 1)
		var bi := MeshInstance3D.new()
		bi.mesh = k.build()
		bi.material_override = mat
		root.remove_child(parts["body"])
		parts["body"] = bi
		root.add_child(bi)
		var rk := MeshKit.new()
		StoneWall.rubble(rk, o["pos"])
		var ri := MeshInstance3D.new()
		ri.mesh = rk.build()
		ri.material_override = mat
		root.remove_child(parts["rubble"])
		parts["rubble"] = ri
		ri.scale = Vector3(1.3, 0.7, 1.3)
		root.add_child(ri)
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


func _do_throw_ally(dest: Vector2i) -> void:
	var u := sel
	var ally := _landing_ally
	state = State.BUSY
	_show_tiles({})
	_forecast.text = ""
	_update_status()
	u["cd"][_cur_ab] = Items.cooldown_for(u, int(abilities[_cur_ab]["cd"]))
	_turn_towards(u, ally["pos"])
	_popup(u, abilities[_cur_ab]["name"], Color(1.0, 0.9, 0.5))
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
	u["cd"][id] = Items.cooldown_for(u, int(ab["cd"]))
	_turn_towards(u, o["pos"])
	_popup(u, ab["name"], Color(1.0, 0.9, 0.5))
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


## Gefesselte Geisel auf einem Nachbarfeld ({} wenn keine).
func _hostage_near(p: Vector2i) -> Dictionary:
	for o in world.objects:
		if o["type"] == "hostage" and o["state"] == "bound" and Grid.dist(p, o["pos"]) == 1:
			return o
	return {}


func _free_hostage(u: Dictionary, o: Dictionary) -> void:
	_close_menu()
	state = State.BUSY
	_show_tiles({})
	_update_status()
	_actor = u
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
	_target_objs = _douse_targets(sel) if Items.consumables()[id].get("douse", false) else []
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


func _popup(u: Dictionary, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font = UiTheme.font(UiTheme.F_TITLE)
	l.font_size = 72 if "\n" not in text else 52
	l.pixel_size = (0.0065 if "\n" in text else 0.008) * popup_scale
	l.outline_size = 16
	l.modulate = color
	l.no_depth_test = true
	l.position = to_world(u["pos"]) + Vector3(0, 1.4, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.6, 0.5 if "\n" not in text else 0.9)
	await tw.finished
	l.queue_free()


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
		if step.has("retreat"):   # {"retreat": "xiulan"}: Gegner zieht sich freiwillig zurueck (kein Tod, kehrt spaeter wieder)
			var rt := _find(step["retreat"])
			if not rt.is_empty():
				units.erase(rt)
				retreated.append(rt["id"])
				await _flee(rt, false)
		if step.has("spawn"):
			for e: Dictionary in step["spawn"]:
				var pos := _free_tile_near(Vector2i(e["pos"][0], e["pos"][1]), {"flying": false})
				_spawn(e["id"], "e", pos, {"carry": e.get("carry", {})})
				var u: Dictionary = units.back()
				await _popup(u, "Verstärkung", Color(1.0, 0.6, 0.4))
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
				continue
			if Status.has(o, "stealth"):
				continue
			if ab.has("require_tag") and not (o["tags"] as Array).has(ab["require_tag"]):
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
				if not o.is_empty() and o["team"] != u["team"] and not Status.has(o, "stealth"):
					out.append(o)
		"area_enemies", "area_allies":
			var center: Vector2i = u["pos"] if ab["target"] == "self" else target["pos"]
			var tiles := _area_tiles(ab, center)
			for o in units:
				if not tiles.has(o["pos"]):
					continue
				var enemy: bool = o["team"] != u["team"]
				if (to == "area_enemies" and enemy and not Status.has(o, "stealth")) or (to == "area_allies" and not enemy):
					out.append(o)
	return out


func _run_ability(u: Dictionary, id: String, target: Dictionary) -> void:
	var ab: Dictionary = abilities[id]
	u["cd"][id] = Items.cooldown_for(u, int(ab["cd"]))
	_actor = u
	_note("ability", {"id": id, "by": u})
	if target != u:
		_turn_towards(u, target["pos"])
	if fx.has_fx(id):
		_popup(u, ab["name"], Color(1.0, 0.9, 0.5))   # Name blendet parallel zur Animation ein
	else:
		await _popup(u, ab["name"], Color(1.0, 0.9, 0.5))
	await fx.windup(id, u, target)
	var tiles := _area_tiles(ab, u["pos"] if ab["target"] == "self" else target["pos"])
	await fx.cast(id, u, target, tiles)
	for ef: Dictionary in ab["effects"]:
		if not units.has(u):
			break
		await _apply_effect(u, ab, target, ef)
	await fx.after(id, u, target)
	_refresh_unit(u)
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
				return o["team"] != u["team"] and o != target and Grid.dist(o["pos"], target["pos"]) == 1)
			for v in near:
				fx.on_splash(ab["id"], u, v)
				await _strike(u, v, ef["mult"], 0.0, false)
		"status":
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
	def["hp"] = maxi(0, def["hp"] - dmg)
	_refresh_unit(def)
	await _popup(def, "-%d\n%s" % [dmg, text], Color(1, 0.45, 0.35))
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
	for u in (units + _away):
		if u["team"] != team:
			continue
		u["done"] = false
		u["charge"] = 0
		var stunned := Status.has(u, "stun")
		for ev: Dictionary in Status.tick_phase_start(u):
			if ev["type"] == "poison":
				u["hp"] = maxi(0, u["hp"] - ev["amount"])
				_refresh_unit(u)
				await _popup(u, "-%d Gift" % ev["amount"], Color(0.6, 1.0, 0.4))
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
	await _begin_phase("e")
	if state == State.OVER:
		return
	await _fire_phase()
	if state == State.OVER:
		return
	for e in units.filter(func(u: Dictionary) -> bool: return u["team"] == "e"):
		if not units.has(e) or e["done"]:
			continue
		await _enemy_move(e)
		if state == State.OVER:
			return
	turn += 1
	await _begin_phase("p")
	if state == State.OVER:
		return
	await _run_triggers("turn", turn)
	_check_end()
	if state == State.OVER:
		return
	state = State.IDLE
	_update_status()
	if _all_done("p"):
		_end_player_turn()


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


func _enemy_move(e: Dictionary) -> void:
	var reach_e := grid.reachable(e["pos"], e["move"], e["flying"], _team_tiles("p"))
	var occupied := {}
	for o in units:
		if o != e:
			occupied[o["pos"]] = true
	if not e["flying"]:
		for ft: Vector2i in world.burning_tiles():
			if ft != e["pos"]:
				occupied[ft] = true      # kein Ziel-/Standfeld im Feuer
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
		for t: Vector2i in reach_e:
			if occupied.has(t):
				continue
			for p in players:
				var dd := Grid.dist(t, p["pos"]) - grid.def_bonus(t) * 0.1
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