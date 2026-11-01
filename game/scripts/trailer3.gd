class_name Trailer3
extends Trailer2
## Trailer 3 (ca. 30 Sekunden) fuer YouTube: Mira, Helden, lustige Faehigkeiten, Schlacht, geheime Interaktion mit Super-Attacke, Abspann.
## Ohne Zahlenangaben (der Umfang steht noch nicht fest), ohne Regent und Bienenkorb. Aufnahme: tools/make_trailer.sh trailer3

const T3_HEROES := [
	[["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"], ["samurai", "wuetend", "Takeda", "Samurai"]],
	[["wendy", "lachend", "Wendy Wolle", "Schaf-Heilerin"], ["claude", "lachend", "Claude", "Flaschengeist-Magier"]],
	[["robo", "", "Robo", "Dampfroboter"], ["hund", "wuetend", "Blauer Hundsfreund", "Knochenkämpfer"]],
	[["quacksalber", "lachend", "Dr. Humbug", "Äußerst seriöser Arzt"], ["magical_girl", "lachend", "Lumi Sternenglanz", "Magical Girl"]],
	[["bienenmaedchen", "wuetend", "Stachelia", "Giftige Fliegerin"], ["braumeisterin", "lachend", "Brunhilde Bräu", "Braumeisterin mit Fass"]],
]
## Echte Zeilen aus dem Spiel (Kapitel 2 bzw. die Rueckzugszeilen von Stachelia, mit Lin als Gegenueber).
const TALK_WART := [
	{"left": "museklaugust", "right": "wart", "speaker": "museklaugust", "text": "Ein Wildschwein! Ich dachte, die gibt es nur im Eintopf."},
	{"left": "museklaugust", "right": "wart", "speaker": "wart", "right_expr": "lachend", "text": "Keine Ahnung, wer du bist, Perückenaugust. Raketen frei!"},
]
const TALK_STACHELIA := [
	{"left": "kungfu", "right": "bienenmaedchen", "speaker": "kungfu", "text": "Sie flieht mit ihrem Honig. Das war ein Stachel zu viel."},
	{"left": "kungfu", "right": "bienenmaedchen", "speaker": "bienenmaedchen", "right_expr": "wuetend", "text": "Ich komme wieder. Mit mehr Bienen!"},
]


func _run() -> void:
	# --- Mira und Brumm
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	_fade.color.a = 1.0
	await _fade_to(0.0, 0.7)
	_say("Ein Mädchen. Ein Bär.")
	await _wait(0.9)
	stage.set_mode("dialog")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], []], 1.4)

	# --- Helden
	_say("Sammle deine Helden")
	for beat: Array in T3_HEROES:
		await _beat(beat, 0.66)

	# --- lustige Faehigkeiten
	await _fade_to(1.0, 0.12)
	_say("Spezialfähigkeiten mit Humor")
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.5
	await _scene(SCENES_A[0])      # Fasswurf
	await _scene(SCENES_A[2])      # Polymorph
	await _scene(SCENES_B[0])      # Bellen
	await _scene(SCENES_B[2])      # Tonikum
	Engine.time_scale = 1.0

	# --- Wart und August, dann der Wurf ueber die Mauer
	_say("Gegner mit Charakter")
	await _talk("ch2", TALK_WART)
	_say("Mauer? Kein Problem.")
	await _throw_scene()

	# --- Schlacht
	_say("Taktik, Zug um Zug")
	await _battle(BATTLE_1.merged({"max_heroes": 3, "max_foes": 2, "speed": 2.0}))

	# --- Stachelia
	_say("Und sie vergessen nichts")
	await _talk("ch1", TALK_STACHELIA)

	# --- Geheimnis und Super-Attacke
	await _fade_to(1.0, 0.12)
	_say("Manche Geheimnisse entdeckt man nur zu zweit")
	await _secret_short()
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	stage.battle.super_music = _duck
	Engine.time_scale = 1.15
	await _scene(DRUNKEN)
	Engine.time_scale = 1.0

	# --- Siegerehrung mit Statistik
	await _fade_to(1.0, 0.15)
	_say("Siegerehrung mit Statistik")
	stage.map_data = Mission.load_mission("ch1")
	stage.new_battle()
	stage.set_mode("dialog")
	_play_music("res://assets/audio/sieg_statistik.mp3", -4.0)
	await _stats_screen()

	# --- Haendler
	_say("Rüste dich aus")
	await _beat([["haendler", "lachend", "Wulle", "Lebender Wollsack, Händler"], []], 1.8)

	# --- Abspann
	await _fade_to(1.0, 0.2)
	_say("")
	_fade_out_music(1.6)
	await _end_card3()
	get_tree().quit()


## Statistik-Bildschirm nach dem Sieg (mit Beispielwerten), ein paar Sekunden.
func _stats_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var rs := RewardScreen.new()
	rs.setup({"gold": 205, "items": {"heiltrank": 1, "gegengift": 1}, "materials": {"kraut": 3}, "equipment": [],
		"objectives": [{"id": "a", "text": "Kein Held fällt", "done": true, "reward": {"gold": 60}}],
		"turns": 7, "stats": {"rows": [
			{"id": "kungfu", "name": "Meister Lin", "alive": true, "hp": 12, "maxhp": 24, "dealt": 41, "taken": 22, "healed": 0, "kills": 3, "abs": 2, "bonus": 1},
			{"id": "wendy", "name": "Wendy Wolle", "alive": true, "hp": 18, "maxhp": 18, "dealt": 6, "taken": 3, "healed": 27, "kills": 0, "abs": 4, "bonus": 0},
			{"id": "braumeisterin", "name": "Brunhilde Bräu", "alive": true, "hp": 30, "maxhp": 34, "dealt": 25, "taken": 9, "healed": 0, "kills": 2, "abs": 1, "bonus": 2}],
			"awards": [{"title": "Schlagkräftigster", "name": "Meister Lin", "text": "41 Schaden ausgeteilt"}, {"title": "Sanitäter", "name": "Wendy Wolle", "text": "27 Leben geheilt"}]}})
	layer.add_child(rs)
	await _fade_to(0.0, 0.15)
	await _wait(2.8)
	await _fade_to(1.0, 0.15)
	layer.queue_free()


## Dialog vor einer Kapitelkarte (Zeilen automatisch weiterschalten).
func _talk(ch: String, lines: Array) -> void:
	await _fade_to(1.0, 0.12)
	stage.map_data = Mission.load_mission(ch)
	stage.new_battle()
	stage.set_mode("dialog")
	var names := {}
	for id: String in unit_defs:
		names[id] = unit_defs[id]["name"]
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var d := Dialogue.new()
	d.setup(lines, names)
	layer.add_child(d)
	await _fade_to(0.0, 0.15)
	for i in lines.size():
		await _wait(0.45 + String(lines[i]["text"]).length() * 0.025 + 0.6)
		d._advance()
	await _fade_to(1.0, 0.12)
	layer.queue_free()


## August wirft Lin ueber die Mauer (Kapitel 2): Anlauf, Flug, Landung bei den Soldaten, Schlag.
func _throw_scene() -> void:
	await _fade_to(1.0, 0.12)
	stage.map_data = Mission.load_mission("ch2")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var aug := _spawn(b, ["museklaugust", "p", [4, 6]])
	var lin := _spawn(b, ["kungfu", "p", [4, 5]])
	var foe := _spawn(b, ["soldat_infanterie", "e", [4, 1]])
	_spawn(b, ["soldat_infanterie", "e", [3, 2]])
	_spawn(b, ["soldat_bogenschuetze", "e", [5, 1]])
	var mid := b.to_world(Vector2i(4, 4))
	b.cam.fov = 40.0
	b.cam.position = mid + Vector3(1.8, 4.6, 5.4)
	b.cam.look_at(mid + Vector3(0, 0.4, -0.8))
	var push := create_tween()
	push.tween_property(b.cam, "position", b.cam.position + Vector3(-0.6, -0.5, -0.9), 3.6)
	await _fade_to(0.0, 0.14)
	await _wait(0.3)
	b._turn_towards(aug, lin["pos"])
	b._popup(aug, "Wurf", Color(1.0, 0.9, 0.5))
	await b.fx.squash(aug, 1.18, 0.85, 0.3)
	await b.fx.leap(lin, Vector2i(4, 2), 2.6, 0.8, 2.0)
	lin["pos"] = Vector2i(4, 2)
	await _wait(0.1)
	await b._resolve(lin, foe)
	await _wait(0.3)
	push.kill()
	await _fade_to(1.0, 0.12)


## Kurze Fassung der Geheimnis-Szene: Banner, Fass, erste Zeile.
func _secret_short() -> void:
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
	d.quick = true
	d.setup_secret(Secrets.by_id("betrunkener_meister"), names)
	layer.add_child(d)
	await _fade_to(0.0, 0.15)
	await _wait(2.4 + 1.2)
	await _fade_to(1.0, 0.15)
	layer.queue_free()


func _duck(on: bool) -> void:
	if _music != null and is_instance_valid(_music):
		create_tween().tween_property(_music, "volume_db", -30.0 if on else -4.0, 0.3)


func _end_card3() -> void:
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
	var a: Label = mk.call("Strategy", 190, 84, UiTheme.GOLD, UiTheme.F_TITLE)
	var b: Label = mk.call("Fantasy", 270, 124, UiTheme.GOLD, UiTheme.F_TITLE)
	var c: Label = mk.call("Demnächst", 450, 36, Color(0.95, 0.9, 0.78), UiTheme.F_HEAD)
	_fade.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.35)
	tw.tween_property(b, "modulate:a", 1.0, 0.35)
	tw.tween_property(c, "modulate:a", 1.0, 0.35)
	await _wait(2.6)
	await _fade_to(1.0, 0.5)
