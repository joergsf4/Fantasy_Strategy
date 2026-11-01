class_name Trailer3
extends Trailer2
## Trailer 3 (ca. 30 Sekunden) fuer YouTube: Mira, Helden, lustige Faehigkeiten, Schlacht, geheime Interaktion mit Super-Attacke, Abspann.
## Ohne Zahlenangaben (der Umfang steht noch nicht fest), ohne Regent und Bienenkorb. Aufnahme: tools/make_trailer.sh trailer3

const T3_HEROES := [
	[["kungfu", "lachend", "Meister Lin", "Kung-Fu mit Stab"], ["elisabeth", "lachend", "Käpt’n Elisabeth", "Piratin mit Kanone"]],
	[["wendy", "lachend", "Wendy Wolle", "Schaf-Heilerin"], ["claude", "lachend", "Claude", "Flaschengeist-Magier"]],
	[["quacksalber", "lachend", "Dr. Humbug", "Äußerst seriöser Arzt"], ["magical_girl", "lachend", "Lumi Sternenglanz", "Magical Girl"]],
]


func _run() -> void:
	# --- Mira und Brumm
	_play_music(TITLE_MUSIC, -4.0)
	stage.set_mode("title")
	_fade.color.a = 1.0
	await _fade_to(0.0, 0.7)
	_say("Ein Mädchen. Ein Bär.")
	await _wait(0.8)
	stage.set_mode("dialog")
	await _beat([["maedchen_baer", "wuetend", "Mira & Brumm", "Der Anfang einer Legende"], []], 1.3)

	# --- Helden
	_say("Sammle deine Helden")
	for beat: Array in T3_HEROES:
		await _beat(beat, 0.62)

	# --- lustige Faehigkeiten
	await _fade_to(1.0, 0.12)
	_say("Spezialfähigkeiten mit Humor")
	_play_music(BATTLE_MUSIC, -4.0)
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.5
	await _scene(SCENES_A[0])      # Fasswurf
	await _scene(SCENES_A[1])      # Wurf (Muskelaugust)
	await _scene(SCENES_A[2])      # Polymorph
	Engine.time_scale = 1.0

	# --- Schlacht
	_say("Taktik, Zug um Zug")
	await _battle(BATTLE_1.merged({"max_heroes": 3, "max_foes": 2, "speed": 2.0}))

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

	# --- Abspann
	await _fade_to(1.0, 0.2)
	_say("")
	_fade_out_music(1.6)
	await _end_card3()
	get_tree().quit()


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
	await _wait(1.9)
	await _fade_to(1.0, 0.4)
