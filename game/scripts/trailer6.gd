class_name Trailer6
extends Trailer5
## Trailer 6: Pseudo-Dokumentarfilm im trockenen Humor. Die Figuren werden einzeln "interviewt" (ruhige Nahaufnahme, Bauchbinde,
## Untertitel mit unbeholfener Pause vor der Pointe), dazwischen Schnittgewitter mit neuer Musik (Frischlinge-Jagd) und Szenen,
## die in keinem Trailer vorkamen: Hogsmeat, Robo-Frischlinge, Xiùlán gegen Oskar, Kugelblitz. Ein Musikabbruch mit Standbild,
## der Strahl der Honigmaschine (hart abgeschnitten vor dem Einschlag, kein Spoiler), Titel, Nachklapp.
## Ohne Regent, Zahlen, Bienenkorb-Kulisse; Mira nur einmal. Aufnahme: tools/make_trailer.sh trailer6

const JAGD_MUSIC := "res://assets/audio/frischlinge_jagd.mp3"

const T6_HOGSMEAT := {"map": "ch20", "fire": false, "cam": [0.0, 5.6, 5.8], "fov": 38, "max_heroes": 3, "max_foes": 2, "speed": 1.5,
	"p": [["maedchen_baer", "p", [5, 7]], ["hund", "p", [4, 7]], ["elisabeth", "p", [3, 7]], ["ritter", "p", [6, 7]]],
	"e": [["hogsmeat_krieger", "e", [4, 4]], ["hogsmeat_krieger", "e", [6, 4]], ["hogsmeat_speerwerfer", "e", [5, 2]], ["hogsmeat_speerwerfer", "e", [7, 3]]]}
const T6_CANNONS := [
	{"ab": "flammenkanone", "u": ["frischling_feuer", "e", [7, 6]], "t": ["ritter", "p", [4, 6]], "more": [], "cam": [0.4, 2.6, 5.0], "fov": 36},
	{"ab": "blitzkanone", "u": ["frischling_blitz", "e", [7, 6]], "t": ["hund", "p", [4, 6]], "more": [["robo", "p", [4, 7]]], "cam": [-0.4, 2.6, 5.0], "fov": 36},
	{"ab": "frostkanone", "u": ["frischling_eis", "e", [7, 6]], "t": ["samurai", "p", [4, 6]], "more": [], "cam": [0.2, 2.4, 4.6], "fov": 34},
]

var _sub_lbl: Label
var _lt_box: Control
var _lt_name: Label
var _lt_role: Label


func _run() -> void:
	_build_cinema()
	_build_doc_ui()
	Engine.time_scale = 1.0
	_fade.color.a = 1.0
	stage.set_mode("title")

	# ================= Kaltstart: ruhige Schrifttafeln =================
	await _wait(0.8)
	await _card("Sie haben die Welt gerettet.", 1.6, 40)
	await _card("Mehr oder weniger.", 1.2, 40)
	await _card("Wir haben ein paar von ihnen gefragt, wie das so war.", 2.0, 34)

	# ================= Interviews =================
	await _interview("ch20", "robo", [5, 6], "Robo", "Dampfroboter",
		"Ich habe berechnet, wie hoch unsere Überlebenschance ist.", "… Ich sage sie euch lieber nicht.")
	await _interview("ch14", "hund", [5, 6], "Der Blaue Hundsfreund", "Knochenkämpfer, Kinderfreund",
		"Den Namen habe ich mir nicht ausgesucht.", "Die Kinder haben abgestimmt. Ich war nicht eingeladen.")

	# ================= Musik setzt ein: Schnittgewitter =================
	_play_music(JAGD_MUSIC, -6.0)
	_hit(0.6)
	await _battle(T6_HOGSMEAT)
	stage.map_data = Mission.load_mission("ch24")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	Engine.time_scale = 1.5
	await _scene(T6_CANNONS[0])
	await _scene(T6_CANNONS[1])
	await _freeze_scene(T6_CANNONS[2])        # Musik bricht ab, Standbild, trockene Frage

	# ================= Gegenseite =================
	await _interview("ch24", "cyborg_wart", [6, 6], "Wart", "Söldner, Vater, Raketenfreund",
		"Das sind meine Jungs.", "Ich bin sehr stolz. Und ein bisschen ängstlich.")
	_play_music(JAGD_MUSIC, -6.0)
	await _brawl_shot()
	await _interview("ch15", "bienenmaedchen", [5, 5], "Stachelia", "gehört nicht zur Gruppe",
		"Ich bin nicht eure Freundin.", "Ich gehe nur zufällig immer in dieselbe Richtung.")
	await _interview("ch23", "kugelblitz", [6, 5], "Professor Kugelblitz", "Wissenschaftler",
		"Wissenschaft heißt, nicht zu wissen, was passiert.", "Darin bin ich sehr, sehr gut.")

	# ================= Der Strahl (ohne Auflösung) =================
	_fade_out_music(0.6)
	await _card("Was soll schon schiefgehen?", 1.4, 40)
	await _beam_shot()
	await _wait(1.1)

	# ================= Titel und Nachklapp =================
	_play_music(JAGD_MUSIC, -8.0)
	await _title_card6()
	_fade_out_music(1.2)
	await _interview("ch1", "wendy", [5, 6], "Wendy Wolle", "Heilerin. Möchte nichts dazu sagen.",
		"Mäh.", "")
	await _fade_to(1.0, 0.4)
	await _wait(0.6)
	get_tree().quit()


# ------------------------------------------------------------------ Doku-Bausteine

func _build_doc_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	_sub_lbl = Label.new()
	_sub_lbl.theme = UiTheme.get_theme()
	_sub_lbl.position = Vector2(80, 600)
	_sub_lbl.size = Vector2(1120, 90)
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_lbl.add_theme_font_override("font", UiTheme.font(UiTheme.F_BODY))
	_sub_lbl.add_theme_font_size_override("font_size", 34)
	_sub_lbl.add_theme_color_override("font_color", Color(1, 1, 0.94))
	_sub_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub_lbl.add_theme_constant_override("outline_size", 9)
	layer.add_child(_sub_lbl)
	_lt_box = Control.new()
	_lt_box.position = Vector2(70, 470)
	_lt_box.modulate.a = 0.0
	layer.add_child(_lt_box)
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.size = Vector2(560, 92)
	_lt_box.add_child(strip)
	var bar := ColorRect.new()
	bar.color = UiTheme.GOLD
	bar.size = Vector2(6, 92)
	_lt_box.add_child(bar)
	_lt_name = Label.new()
	_lt_name.position = Vector2(22, 6)
	_lt_name.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	_lt_name.add_theme_font_size_override("font_size", 32)
	_lt_name.add_theme_color_override("font_color", UiTheme.GOLD)
	_lt_box.add_child(_lt_name)
	_lt_role = Label.new()
	_lt_role.position = Vector2(22, 50)
	_lt_role.add_theme_font_override("font", UiTheme.font(UiTheme.F_BODY))
	_lt_role.add_theme_font_size_override("font_size", 24)
	_lt_role.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
	_lt_box.add_child(_lt_role)


func _subtitle(text: String) -> void:
	_sub_lbl.text = text


## Interview: eine Figur allein auf ihrer Karte, ruhige Nahaufnahme mit leichtem Handkamera-Wackeln, Bauchbinde, zwei Untertitel
## mit einer unbeholfenen Pause dazwischen. Keine Musik (Stille gehoert zum Witz).
func _interview(map_id: String, unit_id: String, tile: Array, who: String, role: String, line1: String, line2: String) -> void:
	await _fade_to(1.0, 0.12)
	_fade_out_music(0.3)
	stage.map_data = Mission.load_mission(map_id)
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var u := _spawn(b, [unit_id, "p", tile])
	(u["ring"] as Node3D).visible = false
	(u["arrow"] as Node3D).visible = false
	var p := b.to_world(u["pos"]) + Vector3(0, 0.35 if u["flying"] else 0.0, 0)      # Flieger schweben hoeher
	b.cam.fov = 34.0
	var base := p + Vector3(0.35, 1.05, 2.5)
	var look := p + Vector3(0, 0.75, 0)
	var wobble := func(t: float) -> void:
		b.cam.position = base + Vector3(sin(t * 1.3) * 0.035, sin(t * 1.9 + 1.0) * 0.025, sin(t * 0.7) * 0.03)
		b.cam.look_at(look + Vector3(sin(t * 1.1 + 2.0) * 0.02, 0, 0))
	wobble.call(0.0)
	var dur := 1.2 + line1.length() * 0.055 + 1.1 + line2.length() * 0.055 + 0.9
	var hand := create_tween()
	hand.tween_method(wobble, 0.0, dur + 1.0, dur + 1.0)
	_lt_name.text = who
	_lt_role.text = role
	await _fade_to(0.0, 0.2)
	create_tween().tween_property(_lt_box, "modulate:a", 1.0, 0.3)
	await _wait(0.6)
	_subtitle(line1)
	await _wait(0.6 + line1.length() * 0.055)
	_subtitle("")
	await _wait(1.1)                       # die unbeholfene Pause
	if line2 != "":
		_subtitle(line2)
		await _wait(0.5 + line2.length() * 0.055)
	await _wait(0.4)
	_subtitle("")
	create_tween().tween_property(_lt_box, "modulate:a", 0.0, 0.2)
	await _fade_to(1.0, 0.15)
	hand.kill()


## Wartet echte Zeit (auch wenn die Spielzeit angehalten ist).
func _wait_real(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


## Faehigkeits-Szene, die mitten im Treffer einfriert: Musik bricht hart ab, Standbild, zwei trockene Untertitel.
func _freeze_scene(sc: Dictionary) -> void:
	var done := [false]
	var run := func() -> void:
		await _scene(sc)
		done[0] = true
	run.call()
	await _wait(1.25)
	if _music != null:
		_music.stop()
	Engine.time_scale = 0.0
	Sfx.play("boing", -6.0, 0.6)
	await _wait_real(0.9)
	_subtitle("Moment.")
	await _wait_real(1.2)
	_subtitle("Haben die Ferkel da gerade Kanonen?")
	await _wait_real(2.0)
	_subtitle("")
	Engine.time_scale = 1.5
	while not done[0]:
		await get_tree().process_frame
	Engine.time_scale = 1.0


## Xiùlán gegen Oskar (Eroeffnung Mission 21): Pruegelwolke, Oskar fliegt in die Kamera und aus dem Bild.
func _brawl_shot() -> void:
	await _fade_to(1.0, 0.12)
	stage.map_data = Mission.load_mission("ch21")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var x := _spawn(b, ["xiulan", "p", [5, 4]])
	var mn: Node = get_parent()
	var o: Dictionary = mn._spawn_oskar_ch21(b)
	stage.mission_twenty_one_camera()
	await _fade_to(0.0, 0.15)
	await _wait(0.3)
	await mn._xiulan_brawl(b, x, o)
	await _wait(0.4)
	await _fade_to(1.0, 0.15)
	stage.set_mode("battle")


## Der Strahl der Honigmaschine im Thronsaal (Mission 25): Stachelia fuellt ein, die Maschine laedt auf, der Strahl schiesst los.
## Harter Schnitt auf Schwarz im Moment des Einschlags, danach Stille: was der Strahl anrichtet, bleibt offen.
func _beam_shot() -> void:
	stage.map_data = Mission.load_mission("ch25")
	stage.new_battle()
	stage.set_mode("battle")
	_prep_battle()
	var b := stage.battle
	for u in b.units.duplicate() + b._away.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b._enter_close_view()
	var hm := b.world.by_id("honigmaschine")
	var cage := b.world.by_id("kaefig_sack")
	var bee := _spawn(b, ["bienenmaedchen", "p", [hm["pos"].x - 1, hm["pos"].y]])
	(bee["ring"] as Node3D).visible = false
	(bee["arrow"] as Node3D).visible = false
	var mid := (b.to_world(hm["pos"]) + b.to_world(cage["pos"])) * 0.5
	b.cam.fov = 44.0
	b.cam.position = mid + Vector3(0.0, 7.0, 8.0)
	b.cam.look_at(mid + Vector3(0, 0.3, -0.5))
	var push := create_tween()
	push.tween_property(b.cam, "position", b.cam.position + Vector3(0, -0.8, -1.2), 4.0)
	await _fade_to(0.0, 0.3)
	await _wait(0.4)
	b.world.apply(hm, "fill")
	b._refresh_object(hm, true)
	await _wait(0.8)
	b._energy_beam(b.to_world(hm["pos"]) + Vector3(0, 1.25, 0), b.to_world(cage["pos"]) + Vector3(0, 0.85, 0), Color(1.0, 0.78, 0.22))
	await _wait(2.75)                      # kurz vor dem Einschlag
	_fade.color.a = 1.0
	push.kill()
	AudioServer.set_bus_mute(0, true)      # Schnitt auch im Ton
	await _wait(1.0)
	AudioServer.set_bus_mute(0, false)


## Titelkarte im neuen Stil: der Titel knallt gross herein und federt zurueck, Bildwackeln, Farbblitz; trockener Untertitel.
func _title_card6() -> void:
	for nd in _sc_layer.get_children():
		nd.queue_free()
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	var root := Control.new()
	root.theme = UiTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.05, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var mk := func(text: String, y: float, size: int, color: Color, font: String, outline := 12) -> Label:
		var l := Label.new()
		l.text = text
		l.position = Vector2(0, y)
		l.size = Vector2(1280, size * 1.5)
		l.pivot_offset = Vector2(640, size * 0.75)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", UiTheme.font(font))
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08))
		l.add_theme_constant_override("outline_size", outline)
		l.modulate.a = 0.0
		root.add_child(l)
		return l
	var t: Label = mk.call("FUZAKETA TACTICS", 220, 92, Color(1.0, 0.86, 0.35), UiTheme.F_TITLE, 16)
	var a: Label = mk.call("フザケタ・タクティクス", 130, 54, Color(1.0, 0.45, 0.75), UiTheme.F_JP)
	var s: Label = mk.call("Ein Spiel über Freundschaft. Und Ferkel mit Kanonen.", 380, 34, Color(0.95, 0.93, 0.88), UiTheme.F_BODY, 8)
	var pl: Label = mk.call("Für Windows und macOS", 470, 26, Color(0.75, 0.72, 0.8), UiTheme.F_HEAD, 6)
	await _fade_to(0.0, 0.05)
	t.scale = Vector2(2.2, 2.2)
	_hit(0.55)
	_flash_rect.color = Color(1.0, 0.4, 0.8, 0.7)
	create_tween().tween_property(_flash_rect, "color:a", 0.0, 0.45)
	var tw := create_tween()
	tw.tween_property(t, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(t, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "modulate:a", 1.0, 0.25)
	tw.tween_interval(0.7)
	tw.tween_property(s, "modulate:a", 1.0, 0.5)
	tw.tween_property(pl, "modulate:a", 1.0, 0.4)
	var shake := create_tween()
	for i in 6:
		shake.tween_property(root, "position", Vector2(randf_range(-10, 10), randf_range(-8, 8)), 0.04)
	shake.tween_property(root, "position", Vector2.ZERO, 0.05)
	await tw.finished
	await _wait(2.4)
	await _fade_to(1.0, 0.3)
	_flash_rect.color = Color(1, 1, 1, 0)
	layer.queue_free()
