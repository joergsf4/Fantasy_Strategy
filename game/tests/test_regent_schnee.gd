extends SceneTree
## godot --headless --path game --script tests/test_regent_schnee.gd
## Kapitel 19 "Der Regent im Schnee": keine Feinde zu Beginn (kein Sofortsieg), Naehern an die Huette loest den Regenten und Robowart mit den Frischlingen aus,
## faellt der Regent, ist die Mission verloren.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch19")
	check(m["goals"][0]["type"] == "rout_spawned" and str(m["lose_if_fallen"]) == "fuerst_lumpen", "Ziel und Niederlagenregel")
	check(m.has("interlude_before") and m["interlude_before"]["scene"] == "snow", "Zwischensequenz im Schneesturm vor der Mission")
	for id: String in ["fuerst_lumpen", "cyborg_wart", "frischlinge"]:
		check(defs.has(id), "Einheit %s existiert" % id)
	for e in ["fuerst_lumpen", "fuerst_lumpen_weinerlich"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % e), "Portrait %s" % e)
	check(ResourceLoader.exists("res://assets/tokens/fuerst_lumpen.png") and ResourceLoader.exists("res://assets/fx/fx_huette.png"), "Karten-Bilder von Regent und Huette")
	var fixed := Mission.dialogue_ids("ch19")
	check(fixed.has("maedchen_baer") and fixed.has("hund") and not fixed.has("ritter") and not fixed.has("wendy"), "feste Figuren: %s" % [fixed])
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_ch19.json"))
	var outro: Array = Mission.voiced(story["outro"], ["maedchen_baer", "hund"])
	check(outro.any(func(line: Dictionary) -> bool: return line["speaker"] == "fuerst_lumpen" and line["text"].contains("flammenden Berg der Vorsehung") and line["text"].contains("geheimen Basis")), "Morgrim nennt das Versteck des Meisters")
	check(outro.any(func(line: Dictionary) -> bool: return line["speaker"] == "hund" and line["text"].contains("Hogsmeat")), "Hund nennt Hogsmeat, wenn er dabei ist")
	var fallback: Array = Mission.voiced(story["outro"], ["maedchen_baer"])
	check(fallback.any(func(line: Dictionary) -> bool: return line["speaker"] == "maedchen_baer" and line["text"].contains("Hogsmeat")), "Mira nennt Hogsmeat als Rueckfallstimme")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(l["speaker"])
	root.add_child(b)
	await process_frame
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	check(b._count_team("e") == 0 and not b.goal_met(), "Keine Feinde zu Beginn, aber kein Sofortsieg")
	check(Mission.goal_text(b.goal, 0, 1, b._capture_info()).begins_with("Ziel: Seht nach"), "Zieltext vor dem Auftritt")
	await b._check_end()
	check(got.is_empty() and b.state != Battle.State.OVER, "Mission laeuft weiter")
	# Die Gruppe startet nah genug: ein Held erreicht mit einem Zug die Huette (Abstand 5), ohne mehrere Runden zu laufen
	var closest := 99
	for u in b.units:
		closest = mini(closest, Grid.dist(u["pos"], Vector2i(1, 3)))
	check(closest <= 7, "Start nah an der Huette: naechster Held %d Felder entfernt" % closest)
	var mira := b._find("maedchen_baer")
	b._select(mira)
	var move_count := 0
	for p: Vector2i in b.reach:
		if p != mira["pos"] and b.unit_at(p).is_empty():
			move_count += 1
	var snow_move_count := 0
	for marker in b._hl_root.get_children():
		var marker_mat := marker.material_override as StandardMaterial3D
		if marker_mat.albedo_color == Battle.COL_MOVE_SNOW:
			snow_move_count += 1
	check(move_count > 0 and snow_move_count == move_count and b._hl_root.get_child_count() == move_count + 1, "Schnee-Bewegungsfelder verwenden die normale Kachelform mit leicht angepasstem Farbton (%d Felder)" % move_count)
	b._show_tiles({Vector2i.ZERO: Battle.COL_ATTACK})
	await process_frame
	check(b._hl_root.get_child_count() == 1, "Angriffsmarker bleibt eine einzelne normale Kachel")
	# Held naehert sich der Huette (Huette bei (1,3), Abstand 5)
	mira["pos"] = Vector2i(4, 5)
	await b._flush_events()
	check(not b._find("fuerst_lumpen").is_empty() and b._find("fuerst_lumpen")["team"] == "p", "Der Regent tritt als Schuetzling auf")
	check(b._count_team("e") == 2 and b._find("cyborg_wart").size() > 0 and b._find("frischlinge").size() > 0, "Robowart und die Frischlinge (eine Figur) erscheinen")
	check(said.has("fuerst_lumpen") and said.has("cyborg_wart") and said.has("frischlinge"), "Dialoge gelaufen: %s" % [said])
	check(Mission.goal_text(b.goal, 2, 1, b._capture_info()).contains("2 übrig") and not b.goal_met(), "Ziel jetzt: Gegner besiegen")
	# Faellt der Regent, ist die Mission verloren
	var regent := b._find("fuerst_lumpen")
	regent["hp"] = 1
	await b._deal(regent, 99, "")
	await b._check_end()
	check(got == [false], "Regent gefallen: Mission verloren (%s)" % [got])
	b.queue_free()
	for player: AudioStreamPlayer in Sfx.get_inst()._players:
		player.stop()
	await process_frame
	Engine.time_scale = 1.0
	await create_timer(0.2).timeout
	print("regent_schnee: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
