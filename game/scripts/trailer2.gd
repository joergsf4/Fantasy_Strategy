class_name Trailer2
extends Trailer
## Trailer 2 (ca. 2 Minuten) fuer YouTube, direkt aus dem Spiel: Prolog, Helden, Spezialfaehigkeiten, Welten, Geheimnis, Abspann.
## Aufnahme: SHOT=trailer2 godot --path game --write-movie out.avi --fixed-fps 30   (tools/make_trailer.sh trailer2)

## Helden-Auftritte nach Mira (sie hat ihren eigenen Auftritt zu Beginn).
const HEROES := [
	[["ritter", "", "Ser Albrecht", "Gealterter Ritter"], ["samurai", "wuetend", "Takeda", "Samurai"]],
	[["kungfu", "lachend", "Meister Lin", "Kung-Fu mit Stab"], ["ninjas", "", "Kage-Schwestern", "Ninja-Duo"]],
	[["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"], ["museklaugust", "wuetend", "Muskelaugust", "Kurfürst und König"]],
	[["robo", "", "Robo", "Dampfroboter"], ["hund", "wuetend", "Blauer Hundsfreund", "Knochenkämpfer"]],
	[["wendy", "lachend", "Wendy Wolle", "Schaf-Heilerin"], ["claude", "lachend", "Claude", "Flaschengeist-Magier"]],
	[["bienenmaedchen", "wuetend", "Stachelia", "Giftige Fliegerin"], ["braumeisterin", "lachend", "Brunhilde Bräu", "Braumeisterin mit Fass"]],
	[["quacksalber", "lachend", "Dr. Humbug", "Äußerst seriöser Arzt"], ["magical_girl", "lachend", "Lumi Sternenglanz", "Magical Girl"]],
]

## Faehigkeits-Szenen (die lustigen): map = Kapitelkarte (Standard ch1), cam = Versatz zur Mitte, status = Dauerstatus fuer den Helden.
const SCENES_A := [
	{"ab": "fasswurf", "u": ["braumeisterin", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_beritten", "e", [7, 7]]], "cam": [0.4, 3.0, 5.6], "fov": 38},
	{"ab": "wurf", "u": ["museklaugust", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_beritten", "e", [7, 6]]], "cam": [1.2, 3.6, 5.2], "fov": 38},
	{"ab": "polymorph", "u": ["claude", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 7]]], "cam": [-0.4, 2.8, 5.4], "fov": 36},
	{"ab": "gebiss", "u": ["xiulan", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_beritten", "e", [7, 7]]], "cam": [0.2, 2.8, 5.4], "fov": 36},
]
const SCENES_B := [
	{"ab": "bellen", "u": ["hund", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_infanterie", "e", [5, 5]], ["soldat_beritten", "e", [3, 8]]], "cam": [1.4, 4.2, 4.6], "fov": 38},
	{"ab": "bearhug", "u": ["museklaugust", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_beritten", "e", [6, 7]]], "cam": [0.2, 2.6, 4.2], "fov": 34},
	{"ab": "tonikum", "u": ["quacksalber", "p", [3, 7]], "tile": [5, 7], "more": [["ritter", "p", [5, 7]], ["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]]], "cam": [-0.2, 3.6, 5.2], "fov": 38},
]
## Schlachtszenen: echte Zuege (Helden laufen und greifen an, danach ziehen die Gegner nach).
const BATTLE_1 := {"map": "ch3", "fire": true, "cam": [0.0, 6.2, 6.4], "fov": 38,
	"p": [["ritter", "p", [3, 6]], ["samurai", "p", [3, 7]], ["kungfu", "p", [4, 5]], ["elisabeth", "p", [2, 8]]],
	"e": [["soldat_infanterie", "e", [7, 6]], ["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [8, 5]], ["soldat_bogenschuetze", "e", [8, 8]], ["soldat_infanterie", "e", [7, 8]]]}
const BATTLE_2 := {"map": "ch7", "fire": false, "cam": [0.0, 6.4, 6.6], "fov": 38,
	"p": [["robo", "p", [3, 6]], ["hund", "p", [3, 7]], ["ninjas", "p", [2, 7]], ["wendy", "p", [2, 6]]],
	"e": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [8, 6]], ["soldat_infanterie", "e", [8, 7]], ["soldat_bogenschuetze", "e", [9, 7]], ["soldat_infanterie", "e", [7, 8]]]}
const DRUNKEN := {"ab": "drunken_strike", "u": ["kungfu", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_infanterie", "e", [6, 7]], ["soldat_beritten", "e", [5, 6]]],
	"cam": [0.8, 2.8, 4.4], "fov": 34, "status": ["betrunken"]}


func _run() -> void:
	# --- 1) Mira und Brumm
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	_fade.color.a = 1.0
	await _fade_to(0.0, 0.8)
	_say("Ein Mädchen. Ein Bär.")
	await _wait(1.4)
	stage.set_mode("dialog")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], []], 1.7)

	# --- 2) Helden
	_say("Sammle deine Helden")
	for beat: Array in HEROES:
		await _beat(beat, 0.74)

	# --- 3) Spezialfaehigkeiten (die lustigen) und Schlachten
	await _fade_to(1.0, 0.15)
	_say("Über 30 Spezialfähigkeiten")
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.4
	for sc: Dictionary in SCENES_A:
		await _scene(sc)
	Engine.time_scale = 1.0
	_say("Echte Schlachten, Zug um Zug")
	await _battle(BATTLE_1)
	_say("Zerstören. Heilen. Verzaubern.")
	Engine.time_scale = 1.4
	for sc: Dictionary in SCENES_B:
		await _scene(sc)
	Engine.time_scale = 1.0
	_say("Jede Karte ein neues Abenteuer")
	await _battle(BATTLE_2)

	# --- 5) Geheimnis (kurzer Ausblick)
	await _fade_to(1.0, 0.15)
	_say("Und manche Geheimnisse entdeckt man nur zu zweit")
	await _secret()
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.3
	await _scene(DRUNKEN)
	Engine.time_scale = 1.0

	# --- 6) Abspann
	await _fade_to(1.0, 0.2)
	_say("")
	_fade_out_music(2.0)
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


## Schlachtszene: zwei Seiten auf einer Kapitelkarte, die Helden greifen der Reihe nach an, dann ziehen die Gegner.
func _battle(sc: Dictionary) -> void:
	await _fade_to(1.0, 0.15)
	stage.map_data = Mission.load_mission(sc["map"])
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	if sc["fire"]:
		var n := 0
		for o in b.world.objects:
			if o["type"] == "house" and n < 3:
				o["state"] = "burning"
				b._refresh_object(o, true)
				n += 1
	var heroes: Array[Dictionary] = []
	var foes: Array[Dictionary] = []
	for spec: Array in sc["p"]:
		heroes.append(_spawn(b, spec))
	for spec: Array in sc["e"]:
		foes.append(_spawn(b, spec))
	var mid := Vector3.ZERO
	for u in heroes + foes:
		mid += b.to_world(u["pos"])
	mid /= float(heroes.size() + foes.size())
	var off: Array = sc["cam"]
	b.cam.fov = float(sc["fov"])
	b.cam.position = mid + Vector3(off[0], off[1], off[2])
	var look := mid + Vector3(0, 0.2, 0)
	b.cam.look_at(look)
	var drift := create_tween()
	drift.tween_property(b.cam, "position", b.cam.position + Vector3(0.6, -0.7, -0.9), 7.0)
	await _fade_to(0.0, 0.15)
	Engine.time_scale = 1.4
	for h in heroes:
		var target := _nearest(b, h, foes)
		if target.is_empty():
			continue
		await _engage(b, h, target)
		foes = foes.filter(func(f: Dictionary) -> bool: return b.units.has(f))
	for f in foes.duplicate():
		if b.units.has(f):
			await b._enemy_move(f)
	Engine.time_scale = 1.0
	drift.kill()
	await _fade_to(1.0, 0.15)


func _nearest(b: Battle, u: Dictionary, others: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var bd := 9999
	for o in others:
		if b.units.has(o) and Grid.dist(u["pos"], o["pos"]) < bd:
			bd = Grid.dist(u["pos"], o["pos"])
			best = o
	return best


## u laeuft auf ein Feld in Angriffsreichweite von target (das naechste) und greift an.
func _engage(b: Battle, u: Dictionary, target: Dictionary) -> void:
	var reach := b.grid.reachable(u["pos"], Combat.move_of(u), u["flying"], b._team_tiles("e"))
	var occupied := {}
	for o in b.units:
		if o != u:
			occupied[o["pos"]] = true
	var best: Vector2i = u["pos"]
	var best_d := 9999
	for t: Vector2i in reach:
		if occupied.has(t) or not Combat.in_range(u, Grid.dist(t, target["pos"])):
			continue
		var d := Grid.dist(t, u["pos"])
		if d < best_d:
			best_d = d
			best = t
	b.reach = reach
	if best != u["pos"]:
		await b._walk(u, best)
	if Combat.in_range(u, Grid.dist(u["pos"], target["pos"])):
		await b._resolve(u, target)


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
	pan.tween_method(set_cam, 0.0, 1.0, 3.4)
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
	tw.tween_interval(2.2)
	tw.tween_property(_sub_label, "modulate:a", 0.0, 0.3)


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
	dim.color = Color(0.02, 0.03, 0.08, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var d := SecretScene.new()
	d.setup_secret(Secrets.by_id("betrunkener_meister"), names)
	layer.add_child(d)
	await _fade_to(0.0, 0.25)
	await _wait(3.4)        # Banner, dann erste Zeile
	await _wait(1.0)
	d._advance()
	await _wait(0.4 + 40 * 0.025 + 0.4)
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
	await _wait(4.4)
	await _fade_to(1.0, 0.6)
