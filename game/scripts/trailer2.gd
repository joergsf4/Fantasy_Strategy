class_name Trailer2
extends Trailer
## Trailer 2 (ca. 2 Minuten) fuer YouTube, direkt aus dem Spiel: Prolog, Helden, Spezialfaehigkeiten, Welten, Geheimnis, Abspann.
## Aufnahme: SHOT=trailer2 godot --path game --write-movie out.avi --fixed-fps 30   (tools/make_trailer.sh trailer2)

const VILLAINS := [
	[["wart", "wuetend", "Wart", "Söldner mit Raketenwerfer"], ["xiulan", "lachend", "Xiùlán", "Oma mit Gebiss-Wurf"]],
	[["oskar", "lachend", "Oskar", "General mit Charme"], ["maja", "wuetend", "Maja", "Eisiger Blick"]],
]
const NEW_HEROES := [
	[["quacksalber", "lachend", "Dr. Humbug", "Äußerst seriöser Arzt"], ["magical_girl", "lachend", "Lumi Sternenglanz", "Magical Girl"]],
	[["bienenmaedchen", "wuetend", "Stachelia", "Giftige Fliegerin"], ["braumeisterin", "lachend", "Brunhilde Bräu", "Braumeisterin mit Fass"]],
]

## Faehigkeits-Szenen: map = Kapitelkarte (Standard ch1), cam = Versatz zur Mitte, status = Dauerstatus fuer den Helden.
const SCENES := [
	{"ab": "sternschnuppe", "u": ["magical_girl", "p", [2, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_bogenschuetze", "e", [6, 6]]], "cam": [-0.6, 3.4, 5.8], "fov": 40},
	{"ab": "brandbombe", "u": ["oskar", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 8]], ["soldat_beritten", "e", [6, 6]]], "cam": [0.4, 3.0, 5.4], "fov": 36},
	{"ab": "kanone", "u": ["elisabeth", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [6, 6]]], "cam": [-1.8, 3.2, 5.6], "fov": 36},
	{"ab": "hinterhalt", "u": ["ninjas", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7], {"dir": [1, 0]}], "more": [["soldat_infanterie", "e", [7, 7]]], "cam": [0.6, 2.6, 4.2], "fov": 34},
	{"ab": "todeswirbel", "u": ["samurai", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [5, 8]], ["soldat_infanterie", "e", [4, 7]]], "cam": [2.2, 4.6, 4.0], "fov": 36},
	{"ab": "tonikum", "u": ["quacksalber", "p", [3, 7]], "tile": [5, 7], "more": [["ritter", "p", [5, 7]], ["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]]], "cam": [-0.2, 3.6, 5.2], "fov": 38},
	{"ab": "bearhug", "u": ["museklaugust", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_beritten", "e", [6, 7]]], "cam": [0.2, 2.6, 4.2], "fov": 34},
	{"ab": "roter_laser", "u": ["robo", "p", [3, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_beritten", "e", [6, 7]], ["soldat_infanterie", "e", [7, 7]], ["kungfu", "p", [4, 7]]], "cam": [1.2, 3.6, 5.6], "fov": 40, "look": [5.0, 0.5, 7.0]},
	{"ab": "bellen", "u": ["hund", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_infanterie", "e", [5, 5]], ["soldat_beritten", "e", [3, 8]]], "cam": [1.4, 4.2, 4.6], "fov": 38},
	{"ab": "bienenkorb", "u": ["bienenmaedchen", "p", [4, 7]], "tile": [6, 7], "more": [["soldat_infanterie", "e", [9, 7]]], "cam": [1.0, 3.8, 5.4], "fov": 38},
	{"ab": "stabwirbel", "u": ["kungfu", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [4, 8]]], "cam": [2.0, 4.4, 4.2], "fov": 36},
	{"ab": "wollmantel", "u": ["wendy", "p", [3, 7]], "t": ["ritter", "p", [5, 7]], "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [7, 6]]], "cam": [-0.2, 3.4, 5.4], "fov": 38},
	{"ab": "prost", "u": ["braumeisterin", "p", [4, 7]], "t": ["ritter", "p", [5, 7], {"hp": 14}], "more": [["soldat_infanterie", "e", [8, 7]]], "cam": [0.2, 2.8, 4.6], "fov": 36},
	{"ab": "baerengebruell", "u": ["maedchen_baer", "p", [4, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 6]]], "cam": [0.4, 2.8, 5.0], "fov": 36},
	{"ab": "kyujutsu", "u": ["samurai", "p", [2, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_beritten", "e", [7, 7]]], "cam": [0.2, 3.2, 6.0], "fov": 40},
	{"ab": "polymorph", "u": ["claude", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 7]]], "cam": [-0.4, 2.8, 5.4], "fov": 36},
]
const DRUNKEN := {"ab": "drunken_strike", "u": ["kungfu", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_infanterie", "e", [6, 7]], ["soldat_beritten", "e", [5, 6]]],
	"cam": [0.8, 2.8, 4.4], "fov": 34, "status": ["betrunken"]}


func _run() -> void:
	# --- 1) Prolog: ein friedliches Tal, der Regent, Mira und Brumm
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	_fade.color.a = 1.0
	await _fade_to(0.0, 1.2)
	_say("Ein friedliches Tal.")
	await _wait(4.0)
	_say("Dann kommt der Regent.")
	stage.set_mode("dialog")
	await _beat([["fuerst", "lachend", "Der Regent", "Steuern. Rückwirkend. Mit Zinsen."], []], 3.2)
	_say("Sein Gegner? Ein Mädchen. Ein Bär.")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], ["ritter", "", "Ser Albrecht", "Gealterter Ritter"]], 3.0)

	# --- 2) Helden
	_say("Sammle deine Helden")
	for beat: Array in SHOWCASE.slice(0, 6):
		await _beat(beat, 1.0)
	for beat: Array in NEW_HEROES:
		await _beat(beat, 1.1)
	_say("… und Schurken mit Charakter")
	for beat: Array in VILLAINS:
		await _beat(beat, 1.3)

	# --- 3) Spezialfaehigkeiten
	await _fade_to(1.0, 0.2)
	_say("Über 30 Spezialfähigkeiten")
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.15
	var n := 0
	for sc: Dictionary in SCENES:
		await _scene(sc)
		n += 1
		if n == 4:
			_say("Zerstören. Heilen. Verzaubern.")
		elif n == 9:
			_say("Jede Figur hat ihren Auftritt")
	Engine.time_scale = 1.0

	# --- 4) Welten
	_say("Sieben Kapitel. Sieben Welten.")
	await _world("ch3", true)
	await _world("ch4", false)
	await _world("ch5", false)
	await _dialogue_part()
	await _world("ch6", false)
	await _world("ch7", false)
	_say("Taktik auf lebendiger Karte")
	stage.map_data = Mission.load_mission("ch1")
	await _map_part()

	# --- 5) Geheimnis
	await _fade_to(1.0, 0.2)
	_say("… und Geheimnisse, die man nur zu zweit entdeckt")
	await _secret()
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.15
	await _scene(DRUNKEN)
	Engine.time_scale = 1.0

	# --- 6) Abspann
	await _fade_to(1.0, 0.25)
	_say("")
	stage.set_mode("dialog")
	await _fade_to(0.0, 0.2)
	_say("Händler, Brauen, Ausrüstung")
	await _beat([["haendler", "lachend", "Wulle", "Lebender Wollsack, Händler"], []], 3.2)
	await _fade_to(1.0, 0.3)
	_say("")
	_fade_out_music(2.5)
	await _end_card2()
	get_tree().quit()


func _prep_battle() -> void:
	stage.battle.popup_scale = 0.62
	stage.battle.fx._hitstop_busy = true     # Zeitlupe beim Treffer passt nicht zum festen Aufnahmetakt


## Ein Paar Portraits fliegt herein, haelt hold Sekunden und fliegt hinaus (wie _showcase).
func _beat(beat: Array, hold: float) -> void:
	var nodes: Array[Control] = []
	var parts: Array = []
	var solo: bool = beat[1].is_empty()
	for i in beat.size():
		var h: Array = beat[i]
		if h.is_empty():
			continue
		var flip := i == 1
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
	await _fade_to(0.0, 0.12)
	for p: Array in parts:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p[0], "position:x", p[2], 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p[1], "modulate:a", 1.0, 0.2).set_delay(0.12)
	await _wait(hold)
	for p: Array in parts:
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(p[0], "position:x", p[3], 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw2.tween_property(p[1], "modulate:a", 0.0, 0.12)
	await _wait(0.18)
	for nd in nodes:
		nd.queue_free()


## Faehigkeits-Szene wie Trailer._ability_scene, dazu Feldziele (tile) und Dauerstatus.
func _scene(sc: Dictionary) -> void:
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var hero := _spawn(b, sc["u"])
	var tgt: Dictionary
	if sc.has("tile"):
		tgt = {"pos": Vector2i(sc["tile"][0], sc["tile"][1]), "tile": true}
	else:
		tgt = hero if str(sc["t"]) == "self" else _spawn(b, sc["t"])
	for o: Array in sc["more"]:
		var u := _spawn(b, o)
		if o.size() > 3 and (o[3] as Dictionary).has("dir"):
			u["dir"] = Vector2i(o[3]["dir"][0], o[3]["dir"][1])
	if sc.get("t") is Array and (sc["t"] as Array).size() > 3 and (sc["t"][3] as Dictionary).has("dir"):
		tgt["dir"] = Vector2i(sc["t"][3]["dir"][0], sc["t"][3]["dir"][1])
	for s: String in sc.get("status", []):
		Status.add(hero, s, 99)
		b._refresh_unit(hero)
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
	var push := create_tween()
	push.tween_property(b.cam, "position", b.cam.position + (look - b.cam.position).normalized() * 0.9, 2.6)
	await _fade_to(0.0, 0.14)
	await _wait(0.2)
	await b._run_ability(hero, sc["ab"], tgt)
	await _wait(0.15)
	push.kill()
	await _fade_to(1.0, 0.12)


## Kapitelkarte mit Figuren: Kamerafahrt ueber die Karte, Kapitelname als Bildunterschrift; fire = Haeuser brennen.
func _world(ch: String, fire: bool) -> void:
	await _fade_to(1.0, 0.15)
	stage.map_data = Mission.load_mission(ch)
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	if fire:
		var n := 0
		for o in b.world.objects:
			if o["type"] == "house" and n < 3:
				o["state"] = "burning"
				b._refresh_object(o, true)
				n += 1
	var title: String = str(stage.map_data.get("title", ""))
	_sub(title)
	var cam := b.cam
	var w := float(b.grid.width)
	var h := float(b.grid.height)
	cam.fov = 38.0
	var set_cam := func(t: float) -> void:
		var f := Vector3(lerpf(2.0, w - 2.5, t), 0.0, (h - 1.0) * 0.5 - 0.4)
		cam.position = f + Vector3(0, 7.2, 6.4)
		cam.look_at(f + Vector3(0, 0.3, 0))
	set_cam.call(0.0)
	await _fade_to(0.0, 0.2)
	var pan := create_tween()
	pan.tween_method(set_cam, 0.0, 1.0, 4.8)
	await pan.finished


## Zweite Bildunterschrift (unten) mit dem Kapitelnamen.
func _sub(text: String) -> void:
	if _sub_label == null:
		var l := CanvasLayer.new()
		l.layer = 9
		add_child(l)
		_sub_label = Label.new()
		_sub_label.theme = UiTheme.get_theme()
		_sub_label.position = Vector2(0, 640)
		_sub_label.size = Vector2(1280, 50)
		_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sub_label.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
		_sub_label.add_theme_font_size_override("font_size", 38)
		_sub_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84))
		_sub_label.add_theme_constant_override("outline_size", 12)
		_sub_label.modulate.a = 0.0
		l.add_child(_sub_label)
	var tw := create_tween()
	tw.tween_property(_sub_label, "modulate:a", 0.0, 0.1)
	tw.tween_callback(func() -> void: _sub_label.text = text)
	tw.tween_property(_sub_label, "modulate:a", 1.0, 0.35)
	tw.tween_interval(3.6)
	tw.tween_property(_sub_label, "modulate:a", 0.0, 0.35)


var _sub_label: Label


## Betrunkener Meister: die Szene der geheimen Interaktion, zwei Zeilen.
func _secret() -> void:
	var names := {}
	for id: String in unit_defs:
		names[id] = unit_defs[id]["name"]
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var d := SecretScene.new()
	d.setup_secret(Secrets.by_id("betrunkener_meister"), names)
	layer.add_child(d)
	await _fade_to(0.0, 0.25)
	await _wait(3.4)        # Banner, dann erste Zeile
	await _wait(1.3)
	d._advance()
	await _wait(0.4 + 90 * 0.025 + 0.9)
	await _fade_to(1.0, 0.25)
	layer.queue_free()


func _end_card2() -> void:
	for nd in _sc_layer.get_children():
		nd.queue_free()
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
	var heroes := 0
	for id: String in unit_defs:
		if unit_defs[id].get("hero", false):
			heroes += 1
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
	var a: Label = mk.call("Strategy", 150, 84, UiTheme.GOLD, UiTheme.F_TITLE)
	var b: Label = mk.call("Fantasy", 230, 124, UiTheme.GOLD, UiTheme.F_TITLE)
	var c: Label = mk.call("7 Kapitel  ·  %d Helden  ·  über 30 Fähigkeiten  ·  Geheimnisse" % heroes, 420, 30, Color(0.95, 0.9, 0.78), UiTheme.F_HEAD)
	var d: Label = mk.call("Demnächst", 500, 38, Color(1.0, 0.96, 0.84), UiTheme.F_HEAD)
	_fade.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.5)
	tw.tween_property(b, "modulate:a", 1.0, 0.5)
	tw.tween_property(c, "modulate:a", 1.0, 0.5)
	tw.tween_property(d, "modulate:a", 1.0, 0.5)
	await _wait(6.5)
	await _fade_to(1.0, 0.8)
