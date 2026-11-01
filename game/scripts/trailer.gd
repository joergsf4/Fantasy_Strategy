class_name Trailer
extends Node
## Teaser-Trailer (ca. 40 s) direkt aus dem Spiel: Titel, Helden, Spezialattacken, Karte, Dialoge, Abspann.
## Aufnahme: SHOT=trailer godot --path game --write-movie out.avi --fixed-fps 30   (siehe tools/make_trailer.sh)

const TITLE_MUSIC := "res://assets/audio/title_theme.mp3"
const BATTLE_MUSIC := "res://assets/audio/battle_theme.mp3"
const PORTRAIT_DIR := "res://assets/portraits/"

const SHOWCASE := [
	[["maedchen_baer", "lachend", "Mira & Brumm", "Mädchen mit Bär"], ["ritter", "", "Ser Albrecht", "Gealterter Ritter"]],
	[["samurai", "wuetend", "Takeda", "Samurai"], ["kungfu", "lachend", "Meister Lin", "Kung-Fu mit Stab"]],
	[["ninjas", "", "Kage-Schwestern", "Ninja-Duo"], ["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"]],
	[["museklaugust", "wuetend", "Muskelaugust", "Kurfürst und König"], ["robo", "", "Robo", "Dampfroboter"]],
	[["hund", "wuetend", "Blauer Hundsfreund", "Knochenkämpfer"], ["wendy", "lachend", "Wendy Wolle", "Schaf-Heilerin"]],
	[["claude", "lachend", "Claude", "Flaschengeist-Magier"], ["bienenmaedchen", "wuetend", "Stachelia", "Giftige Fliegerin"]],
	[["braumeisterin", "lachend", "Brunhilde Bräu", "Braumeisterin mit Fass"], []],
]

## Spezialattacken-Szenen: Figuren und Kamera.
const ABILITY_SCENES := [
	{"ab": "kanone", "u": ["elisabeth", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]],
		"more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [6, 6]], ["soldat_bogenschuetze", "e", [7, 6]]], "cam": [-1.8, 3.2, 5.6], "fov": 36},
	{"ab": "todeswirbel", "u": ["samurai", "p", [5, 7]], "t": "self",
		"more": [["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [5, 8]], ["soldat_infanterie", "e", [4, 7]]], "cam": [2.2, 4.6, 4.0], "fov": 36},
	{"ab": "roter_laser", "u": ["robo", "p", [3, 7]], "t": ["soldat_infanterie", "e", [5, 7]],
		"more": [["soldat_beritten", "e", [6, 7]], ["soldat_infanterie", "e", [7, 7]], ["kungfu", "p", [4, 7]]], "cam": [1.2, 3.6, 5.6], "fov": 40, "look": [5.0, 0.5, 7.0]},
	{"ab": "stabsprung", "u": ["kungfu", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]],
		"more": [["soldat_beritten", "e", [7, 7]]], "cam": [0.6, 3.8, 5.6], "fov": 40},
	{"ab": "polymorph", "u": ["claude", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]],
		"more": [["soldat_infanterie", "e", [7, 7]]], "cam": [-0.4, 2.8, 5.4], "fov": 36},
]

var map_data: Dictionary
var unit_defs: Dictionary
var stage: Stage
var _fade: ColorRect
var _caption: Label
var _music: AudioStreamPlayer
var _sc_layer: CanvasLayer
var _slots: Array[TextureRect] = []


func setup(map: Dictionary, defs: Dictionary) -> void:
	map_data = map
	unit_defs = defs


func _ready() -> void:
	stage = Stage.new()
	stage.setup(map_data, unit_defs)
	add_child(stage)
	_build_overlay()
	_run()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


# ------------------------------------------------------------------ Bausteine

func _build_overlay() -> void:
	var cap_layer := CanvasLayer.new()
	cap_layer.layer = 8
	add_child(cap_layer)
	_caption = Label.new()
	_caption.theme = UiTheme.get_theme()
	_caption.position = Vector2(0, 26)
	_caption.size = Vector2(1280, 50)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	_caption.add_theme_font_size_override("font_size", 30)
	_caption.add_theme_color_override("font_color", UiTheme.GOLD)
	_caption.add_theme_constant_override("outline_size", 9)
	_caption.modulate.a = 0.0
	cap_layer.add_child(_caption)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	_sc_layer = CanvasLayer.new()
	_sc_layer.layer = 3
	add_child(_sc_layer)


func _fade_to(alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	await tw.finished


func _say(text: String) -> void:
	if text == "":
		create_tween().tween_property(_caption, "modulate:a", 0.0, 0.2)
		return
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void: _caption.text = text)
	tw.tween_property(_caption, "modulate:a", 1.0, 0.3)


func _play_music(path: String, db := -5.0) -> void:
	if _music != null:
		var old := _music
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -50.0, 0.8)
		tw.tween_callback(old.queue_free)
	var st: AudioStreamMP3 = load(path)
	st.loop = false
	_music = AudioStreamPlayer.new()
	_music.stream = st
	_music.volume_db = db
	add_child(_music)
	_music.play()


func _fade_out_music(time: float) -> void:
	if _music != null:
		create_tween().tween_property(_music, "volume_db", -50.0, time)


func _plate(name_text: String, sub: String, x: float, flip := false) -> Control:
	var box := VBoxContainer.new()
	box.theme = UiTheme.get_theme()
	box.add_theme_constant_override("separation", 3)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UiTheme.soft_plate(Vector4(40, 8, 40, 10), 0.95))
	var l := Label.new()
	l.text = name_text
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", UiTheme.GOLD)
	l.add_theme_constant_override("outline_size", 5)
	p.add_child(l)
	box.add_child(p)
	var s := Label.new()
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 22)
	s.add_theme_constant_override("outline_size", 5)
	box.add_child(s)
	box.size = Vector2(420, 70)
	box.position = Vector2(x - 210.0, 628)
	return box


func _portrait_slot(id: String, expr: String, flip: bool) -> TextureRect:
	var t := TextureRect.new()
	# Reihenfolge wichtig: erst Skalierung festlegen, dann Bild und Groesse (sonst wird der Rahmen auf Bildgroesse gedehnt)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.flip_h = flip
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var path := PORTRAIT_DIR + id + ".png"
	if expr != "" and ResourceLoader.exists(PORTRAIT_DIR + id + "_" + expr + ".png"):
		path = PORTRAIT_DIR + id + "_" + expr + ".png"
	t.texture = load(path)
	t.size = Vector2(520, 560)
	t.position = Vector2(50 if not flip else 710, 50)
	return t


# ------------------------------------------------------------------ Ablauf

func _run() -> void:
	# 1) Startbildschirm
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	var title := TitleScreen.new()
	add_child(title)
	_fade.color.a = 0.0
	await _wait(4.9)
	await _fade_to(1.0, 0.35)
	title.queue_free()

	# 2) Heldenpraesentation
	stage.set_mode("dialog")
	await _fade_to(0.0, 0.2)
	_say("13 Helden zum Sammeln")
	await _showcase()

	# 3) Spezialattacken
	await _fade_to(1.0, 0.2)
	_say("Spezialattacken in 3D")
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	stage.battle.popup_scale = 0.62
	stage.battle.fx._hitstop_busy = true     # Zeitlupe beim Treffer passt nicht zum festen Aufnahmetakt
	Engine.time_scale = 1.2
	for sc in ABILITY_SCENES:
		await _ability_scene(sc)
	Engine.time_scale = 1.0

	# 4) Karte und Bedienung
	await _fade_to(1.0, 0.15)
	_say("Taktik auf lebendiger Karte")
	await _map_part()

	# 5) Dialoge
	await _fade_to(1.0, 0.2)
	_say("Anime-Dialoge mit Witz")
	await _dialogue_part()

	# 6) Abspann
	await _fade_to(1.0, 0.3)
	_say("")
	_fade_out_music(2.0)
	await _end_card()
	get_tree().quit()


func _showcase() -> void:
	for beat: Array in SHOWCASE:
		var nodes: Array[Control] = []
		var parts: Array = []
		for i in beat.size():
			var h: Array = beat[i]
			if h.is_empty():
				continue
			var flip := i == 1
			var solo: bool = beat[1].is_empty()
			var slot := _portrait_slot(h[0], h[1], flip)
			var center_x := 310.0 if not flip else 970.0
			if solo:
				slot.position.x = 380
				center_x = 640.0
			var plate := _plate(h[2], h[3], center_x)
			var from_x := (-760.0 if not flip else 1340.0) if not solo else -760.0
			var to_x := slot.position.x
			slot.position.x = from_x
			plate.modulate.a = 0.0
			_sc_layer.add_child(slot)
			_sc_layer.add_child(plate)
			nodes.append(slot)
			nodes.append(plate)
			parts.append([slot, plate, to_x, from_x])
		for p: Array in parts:
			var tw := create_tween().set_parallel(true)
			tw.tween_property(p[0], "position:x", p[2], 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(p[1], "modulate:a", 1.0, 0.2).set_delay(0.12)
		await _wait(0.95)
		for p: Array in parts:
			var tw2 := create_tween().set_parallel(true)
			tw2.tween_property(p[0], "position:x", p[3], 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw2.tween_property(p[1], "modulate:a", 0.0, 0.12)
		await _wait(0.18)
		for n in nodes:
			n.queue_free()


func _spawn(b: Battle, spec: Array) -> Dictionary:
	b._spawn(spec[0], spec[1], Vector2i(spec[2][0], spec[2][1]))
	var u: Dictionary = b.units.back()
	(u["label"] as Label3D).visible = false
	(u["bar"] as MeshInstance3D).visible = false
	return u


func _ability_scene(sc: Dictionary) -> void:
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var hero := _spawn(b, sc["u"])
	var tgt: Dictionary = hero if str(sc["t"]) == "self" else _spawn(b, sc["t"])
	for o: Array in sc["more"]:
		_spawn(b, o)
	var mid: Vector3 = (b.to_world(hero["pos"]) + b.to_world(tgt["pos"])) * 0.5
	if tgt == hero:
		mid = b.to_world(hero["pos"])
	var off: Array = sc["cam"]
	b.cam.fov = float(sc["fov"])
	b.cam.position = mid + Vector3(off[0], off[1], off[2])
	var look: Vector3 = mid + Vector3(0, 0.45, 0)
	if sc.has("look"):
		look = Vector3(sc["look"][0], sc["look"][1], sc["look"][2])
	b.cam.look_at(look)
	var push := create_tween()     # langsames Heranfahren
	push.tween_property(b.cam, "position", b.cam.position + (look - b.cam.position).normalized() * 0.9, 2.6)
	await _fade_to(0.0, 0.14)
	await _wait(0.25)
	await b._run_ability(hero, sc["ab"], tgt)
	await _wait(0.2)
	push.kill()
	await _fade_to(1.0, 0.12)


func _map_part() -> void:
	stage.new_battle()
	stage.set_mode("battle")
	var b := stage.battle
	b.fx._hitstop_busy = true
	var cam := b.cam
	var w := float(b.grid.width)
	var h := float(b.grid.height)
	cam.fov = 38.0
	var set_cam := func(t: float) -> void:
		var f := Vector3(lerpf(1.5, w - 2.0, t), 0.0, (h - 1.0) * 0.5 - 0.5)
		cam.position = f + Vector3(0, 8.0, 7.2)
		cam.look_at(f + Vector3(0, 0.3, 0))
	set_cam.call(0.0)
	await _fade_to(0.0, 0.25)
	var pan := create_tween()
	pan.tween_method(set_cam, 0.0, 1.0, 2.5)
	await pan.finished
	# zurueck zur Spielansicht, Oberflaeche an
	var back := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(cam, "transform", b.cam_home, 0.6)
	back.tween_property(cam, "fov", 40.0, 0.6)
	await back.finished
	b._hud_layer.visible = true
	b.state = Battle.State.IDLE
	b._update_status()
	await _wait(0.4)
	var knight := b.unit_at(Vector2i(1, 8))
	b._select(knight)
	b._hover(Vector2i(1, 8))
	await _wait(1.0)
	b._hover(Vector2i(3, 7))
	await _wait(0.4)
	await b._move_player(Vector2i(3, 7))
	await _wait(0.7)
	b._enter_action(true)
	await _wait(1.0)
	b._close_menu()


func _dialogue_part() -> void:
	var b := stage.battle
	b.enter_title_mode()
	stage.set_mode("dialog")
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var lines := [
		{"left": "maedchen_baer", "right": "bienenmaedchen", "speaker": "bienenmaedchen", "right_expr": "lachend",
			"text": "Bsssss... Der Honig des Dorfes gehört jetzt der Königin."},
		{"left": "maedchen_baer", "right": "bienenmaedchen", "speaker": "maedchen_baer", "left_expr": "wuetend",
			"text": "Brumm hat Hunger. Ich glaube, du hast gerade einen Fehler gemacht."},
	]
	var names := {}
	for id: String in unit_defs:
		names[id] = unit_defs[id]["name"]
	var d := Dialogue.new()
	d.setup(lines, names)
	layer.add_child(d)
	await _fade_to(0.0, 0.2)
	await _wait(0.4 + 58 * 0.025 + 0.65)
	d._advance()
	await _wait(0.4 + 68 * 0.025 + 0.9)
	await _fade_to(1.0, 0.2)
	layer.queue_free()


func _end_card() -> void:
	for n in _sc_layer.get_children():
		n.queue_free()
	stage.visible = false
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var root := Control.new()
	root.theme = UiTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var mk := func(text: String, y: float, size: int, color: Color, font: String) -> Label:
		var l := Label.new()
		l.text = text
		l.position = Vector2(0, y)
		l.size = Vector2(1280, size * 1.4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UiTheme.font(font))
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", Color(0.16, 0.08, 0.03))
		l.add_theme_constant_override("outline_size", 12)
		l.modulate.a = 0.0
		root.add_child(l)
		return l
	var a: Label = mk.call("フザケタ・", 170, 100, UiTheme.GOLD, UiTheme.F_JP)
	var b: Label = mk.call("タクティクス", 260, 100, UiTheme.GOLD, UiTheme.F_JP)
	var c: Label = mk.call("Demnächst", 450, 34, Color(0.95, 0.9, 0.78), UiTheme.F_HEAD)
	_fade.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.5)
	tw.tween_property(b, "modulate:a", 1.0, 0.5)
	tw.tween_property(c, "modulate:a", 1.0, 0.5)
	await _wait(2.3)
	await _fade_to(1.0, 0.5)
