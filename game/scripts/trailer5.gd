class_name Trailer5
extends Trailer4
## Trailer 5 (ca. 2 Minuten), "Hollywood-Trailer": Kino-Dramaturgie statt Funktionsliste. Kaltstart, Weltaufbau, Heldenauftritte, Stille und Wendung (nur
## eine Silhouette), Schnittgewitter, Geheimnisse als Hoehepunkt, Titelkarte, Nachspann-Gag. Letterbox 2,39:1, Schrifttafeln, Zeitlupe, Musik-Rampen.
## Ohne Regent, Zahlen, Bienenkorb-Kulisse; Mira nur einmal; nur vorhandene Musik. Aufnahme: tools/make_trailer.sh trailer5

const T5_SEA_TALK := [
	{"left": "hund", "right": "elisabeth", "speaker": "hund", "left_expr": "seekrank", "text": "Mir ist schlecht. Hab ich erwähnt, dass mir schlecht ist?"},
	{"left": "hund", "right": "elisabeth", "speaker": "elisabeth", "right_expr": "lachend", "text": "Schau zum Horizont, Landratte, nicht auf die Wellen."},
]
const T5_SACK := [
	{"left": "haendler", "right": "", "speaker": "haendler", "text": "Ich bin ein Sack. Ich bleibe überall liegen."},
]
const T5_BATTLE_SNOW := {"map": "ch17", "fire": false, "cam": [0.0, 6.0, 6.2], "fov": 38, "max_heroes": 3, "max_foes": 2, "speed": 1.5,
	"p": [["hund", "p", [3, 6]], ["samurai", "p", [3, 7]], ["robo", "p", [2, 6]], ["elisabeth", "p", [2, 7]]],
	"e": [["wolf", "e", [7, 6]], ["wolf", "e", [7, 7]], ["wolf", "e", [8, 6]], ["wolf", "e", [8, 7]], ["soldat_infanterie", "e", [8, 5]]]}
const T5_RAIN := {"throw": true, "u": ["museklaugust", "p", [2, 7]], "t": ["ninjas", "p", [3, 7]], "dest": [6, 7],
	"more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [7, 8]], ["soldat_bogenschuetze", "e", [8, 6]], ["soldat_infanterie", "e", [6, 5]]], "cam": [3.0, 8.0, 5.0], "fov": 46}

var _bar_top: ColorRect
var _bar_bot: ColorRect
var _card_layer: CanvasLayer
var _flash_rect: ColorRect


func _run() -> void:
	_build_cinema()
	Engine.time_scale = 1.0
	_fade.color.a = 1.0
	stage.set_mode("title")
	if OS.get_environment("T5_ONLY") == "lab":      # Entwicklungshilfe: nur die Labor-Szene aufnehmen
		await _bars(true, 0.01)
		await _lab_shot()
		get_tree().quit()
		return

	# ================= Akt 1: Kaltstart =================
	_play_music(TITLE_MUSIC, -22.0)
	create_tween().tween_property(_music, "volume_db", -12.0, 14.0)
	await _wait(1.2)
	await _card("In einem Land …", 2.6)
	await _dusk_shot()
	await _card("… in dem selbst der Honig besteuert wird …", 3.0)
	await _bars(false)
	await _beat([["soldat_beritten", "wuetend", "Büttel", "Ihr Steuerbescheid ist da"], []], 1.7)
	await _fade_to(1.0, 0.2)
	await _card("… steht ein Mädchen auf.", 2.6)
	stage.set_mode("dialog")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], []], 2.6)

	# ================= Akt 2: Aufbau =================
	await _fade_to(1.0, 0.2)
	_play_music(BATTLE_MUSIC, -14.0)
	create_tween().tween_property(_music, "volume_db", -5.0, 9.0)
	await _card("Sie ist nicht allein.", 1.8)
	await _beat([["ritter", "", "Ser Albrecht", "Gealterter Ritter"], ["samurai", "wuetend", "Takeda", "Samurai"]], 1.0)
	await _beat([["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"], ["ninjas", "", "Kage-Schwestern", "Ninja-Duo"]], 1.0)
	await _beat([["hund", "wuetend", "Blauer Hundsfreund", "Knochenkämpfer"], ["robo", "", "Robo", "Dampfroboter"]], 1.0)
	await _fade_to(1.0, 0.15)
	await _card("Kein Hindernis ist zu hoch …", 2.0)
	await _bars(true)
	await _throw_scene()
	await _card("… kein Meer zu weit.", 1.6)
	await _sea_gag()      # blendet Bild und Musik am Ende selbst aus

	# ================= Akt 3: Stille und Wendung =================
	await _wait(1.6)
	await _bars(true, 0.01)
	await _lab_shot()

	# ================= Akt 4: Schnittgewitter =================
	_hit(0.55)
	await _flash()
	_play_music(BATTLE_MUSIC, -2.5)
	Engine.time_scale = 1.0
	await _card("Verrückte Spezialfähigkeiten.", 1.4)
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	for sc: Dictionary in [SCENES_A[0], SCENES_B[0], SCENES_A[2]]:      # Fasswurf, Bellen, Frosch
		Engine.time_scale = 1.6
		await _scene(sc)
	Engine.time_scale = 1.0
	await _battle(T4_BATTLE_DESERT)
	await _card("Taktik an jedem Ort.", 1.4)
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	for sc: Dictionary in [SCENES_A[3], SCENES_B[1], SCENES_B[2]]:      # Gebiss, Bearhug, Tonikum
		Engine.time_scale = 1.6
		await _scene(sc)
	Engine.time_scale = 1.0
	await _battle(T5_BATTLE_SNOW)

	# ================= Akt 5: Hoehepunkt =================
	await _fade_to(1.0, 0.15)
	await _card("Manche Geheimnisse entdeckt man nur zu zweit.", 2.4)
	stage.map_data = Mission.load_mission("ch7")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	stage.battle.super_music = _duck
	Engine.time_scale = 1.0
	await _scene(T5_RAIN)
	Engine.time_scale = 1.0

	# ================= Akt 6 und 7: Titel und Nachspann-Gag =================
	await _fade_to(1.0, 0.2)
	_fade_out_music(0.4)
	await _bars(false)
	await _wait(1.3)
	await _title_card5()
	await _wait(0.8)
	await _talk("ch1", T5_SACK)
	await _fade_to(1.0, 0.4)
	await _wait(0.6)
	get_tree().quit()


# ------------------------------------------------------------------ Kino-Bausteine

func _build_cinema() -> void:
	_card_layer = CanvasLayer.new()
	_card_layer.layer = 21        # ueber der Schwarzblende, unter den Balken
	add_child(_card_layer)
	var bars := CanvasLayer.new()
	bars.layer = 22
	add_child(bars)
	_bar_top = ColorRect.new()
	_bar_bot = ColorRect.new()
	for b: ColorRect in [_bar_top, _bar_bot]:
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = Vector2(1280, 0)
		bars.add_child(b)
	_bar_bot.position = Vector2(0, 720)
	var fl := CanvasLayer.new()
	fl.layer = 23
	add_child(fl)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_flash_rect)


## Kinobalken ein- oder ausfahren (2,39:1 entspricht 92 Pixel oben und unten bei 1280x720).
func _bars(on: bool, time := 0.3) -> void:
	var h := 92.0 if on else 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bar_top, "size:y", h, time)
	tw.tween_property(_bar_bot, "size:y", h, time)
	tw.tween_property(_bar_bot, "position:y", 720.0 - h, time)
	await tw.finished


## Schrifttafel auf Schwarz (wie im Kino): einblenden, halten, ausblenden. Die Schwarzblende muss zu sein.
func _card(text: String, hold: float, size := 46, over_scene := false) -> void:
	if not over_scene:
		_fade.color.a = 1.0
	var l := Label.new()
	l.theme = UiTheme.get_theme()
	l.text = text
	l.position = Vector2(60, 280)
	l.size = Vector2(1160, 160)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.93, 0.9, 0.82))
	l.add_theme_constant_override("outline_size", 0)
	l.modulate.a = 0.0
	_card_layer.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.55)
	tw.tween_interval(hold)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	await tw.finished
	l.queue_free()


func _flash() -> void:
	_flash_rect.color.a = 0.9
	create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.3)
	await _wait(0.05)


## Trommelschlag: tiefer Knall aus den vorhandenen Klaengen (Explosion, Donner) mit Pitch nach unten.
func _hit(pitch := 0.6) -> void:
	Sfx.play("explosion", 2.0, pitch)
	Sfx.play("thunder", 0.0, pitch + 0.2, 0.05)


## Daemmerungs-Bild: Reiter ziehen ueber die Karte (Kamerafahrt, keine Figur ausser den Bütteln).
func _dusk_shot() -> void:
	await _fade_to(1.0, 0.15)
	var m := Mission.load_mission("ch1")
	m["mood"] = "daemmerung"
	stage.map_data = m
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	for spec: Array in [["soldat_beritten", "e", [2, 6]], ["soldat_beritten", "e", [3, 7]], ["soldat_infanterie", "e", [2, 8]], ["soldat_infanterie", "e", [4, 6]], ["soldat_beritten", "e", [4, 8]]]:
		_spawn(b, spec)
	var w := float(b.grid.width)
	var h := float(b.grid.height)
	b.cam.fov = 36.0
	var set_cam := func(t: float) -> void:
		var f := Vector3(lerpf(1.6, w - 3.5, t), 0.0, (h - 1.0) * 0.5 + 0.4)
		b.cam.position = f + Vector3(-2.0, 3.0, 7.0)
		b.cam.look_at(f + Vector3(1.0, 0.5, 0.0))
	set_cam.call(0.0)
	await _bars(true, 0.01)
	await _fade_to(0.0, 0.5)
	var pan := create_tween()
	pan.tween_method(set_cam, 0.0, 1.0, 4.4)
	await pan.finished
	await _fade_to(1.0, 0.3)


## Dialog auf dem Meer (die Ueberfahrt), zwei Zeilen.
func _sea_gag() -> void:
	await _fade_to(1.0, 0.12)
	var names := {}
	for id: String in unit_defs:
		names[id] = unit_defs[id]["name"]
	var sea_layer := CanvasLayer.new()
	sea_layer.layer = 3
	add_child(sea_layer)
	var it := Interlude.new()
	it.setup({"scene": "sea", "dir": "right", "speed": 1.8, "hold": true, "duration": 600.0})
	sea_layer.add_child(it)
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var d := Dialogue.new()
	d.setup(T5_SEA_TALK, names)
	layer.add_child(d)
	await _bars(false, 0.01)
	await _fade_to(0.0, 0.25)
	await _wait(0.5)
	for i in T5_SEA_TALK.size():
		await _wait(0.5 + String(T5_SEA_TALK[i]["text"]).length() * 0.04 + 0.2)
		d._advance()
	_fade_out_music(2.8)                  # Musik und Bild blenden langsam aus
	await _fade_to(1.0, 1.3)
	layer.queue_free()
	sea_layer.queue_free()


## Labor im Gewitter: langsame Fahrt auf den gruenen Glasbehaelter zu. Stille, nur Regen und Donner. Zum Schluss birst das Glas.
func _lab_shot() -> void:
	var m := Mission.load_mission("ch13")
	stage.map_data = m
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var at := b.to_world(Vector2i(10, 2))
	b.cam.fov = 30.0
	b.cam.position = at + Vector3(1.3, 3.6, 4.0)
	b.cam.look_at(at + Vector3(0.8, 0.55, 0))
	var push := create_tween()
	push.tween_property(b.cam, "position", at + Vector3(1.0, 2.5, 2.7), 7.0).set_trans(Tween.TRANS_SINE)
	await _fade_to(0.0, 1.2)
	await _wait(1.8)
	Sfx.event("thunder_far")
	await _card("Manche Gegner kehren zurück.", 2.0, 40, true)
	await _wait(0.3)
	for o in b.world.objects:           # das Glas birst (Explosion, Scherben), danach Blitz und Schwarz
		if o["type"] == "zylinder":
			o["state"] = "broken"
			b._refresh_object(o, true)
	Sfx.play("glass", 3.0, 0.8)
	Sfx.event("thunder")
	await _flash()
	await _wait(0.5)
	await _fade_to(1.0, 0.5)
	push.kill()
	await _wait(0.6)


## Titelkarte: japanische Schrift (wie im Spiel), lateinischer Titel, Slogan, Plattformen. Trommelschlag beim Einblenden.
func _title_card5() -> void:
	for nd in _sc_layer.get_children():
		nd.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	var root := Control.new()
	root.theme = UiTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var mk := func(text: String, y: float, size: int, color: Color, font: String, outline := 12) -> Label:
		var l := Label.new()
		l.text = text
		l.position = Vector2(0, y)
		l.size = Vector2(1280, size * 1.5)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UiTheme.font(font))
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", Color(0.16, 0.08, 0.03))
		l.add_theme_constant_override("outline_size", outline)
		l.modulate.a = 0.0
		root.add_child(l)
		return l
	var a: Label = mk.call("フザケタ・タクティクス", 120, 96, UiTheme.GOLD, UiTheme.F_JP)
	var t: Label = mk.call("FUZAKETA TACTICS", 270, 74, Color(0.98, 0.93, 0.8), UiTheme.F_TITLE)
	var s: Label = mk.call("Rundentaktik, die Spaß macht", 395, 38, Color(0.95, 0.9, 0.78), UiTheme.F_HEAD, 8)
	var p: Label = mk.call("Für Windows und macOS", 480, 26, Color(0.8, 0.78, 0.7), UiTheme.F_HEAD, 6)
	_hit(0.5)
	_flash_rect.color.a = 0.6
	create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.5)
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(t, "modulate:a", 1.0, 0.25).set_delay(0.12)
	tw.tween_interval(0.9)
	tw.tween_property(s, "modulate:a", 1.0, 0.5)
	tw.tween_property(p, "modulate:a", 1.0, 0.4)
	await tw.finished
	await _wait(2.2)
	await _fade_to(1.0, 0.3)
	layer.queue_free()
