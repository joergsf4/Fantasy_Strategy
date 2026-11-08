extends SceneTree
## godot --headless --path game --script tests/test_ch23.gd
## Mission 23 (Zwischenspiel, Biom Basis): Xiùlán darf je Zug nur in ein Versteck des naechsten Schritts, das belauschte Gespraech
## laeuft Versteck fuer Versteck, der Professor handelt nicht; am Ziel taucht Maja auf und schlaegt Xiùlán k.o. Keine Belohnung,
## zaehlt nicht als Kampfmission.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	check(FileAccess.get_file_as_string("res://scripts/main.gd").contains('"ch22", "ch23"'), "Mission 23 steht in der Kapitelliste")
	var m := Mission.load_mission("ch23")
	check(m["no_rewards"] and m["fixed_squad"] and m["goals"][0]["type"] == "reach", "Zwischenspiel ohne Belohnung, feste Gruppe, Ziel erreichen")
	check(Progression.missions_done_before(24) == Progression.missions_done_before(23), "Mission 23 zaehlt nicht als Kampfmission")
	check(Progression.missions_done_before(23) == Progression.missions_done_before(22) + 1, "Mission 22 zaehlt als Kampfmission")
	for f in ["fx_konsole", "fx_reaktor", "fx_serverschrank", "fx_roboterarm", "fx_monitorwand"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % f), "Geraet " + f)
	check(ResourceLoader.exists("res://assets/portraits/schatten.png"), "Schatten-Portrait")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	await process_frame
	var x: Dictionary = b._find("xiulan")
	var prof: Dictionary = b._find("kugelblitz")
	check(not x.is_empty() and prof["idle"] and not b._hittable(prof), "Xiùlán allein, Professor untaetig und unangreifbar")
	var steps: Array = m["hide_steps"] if m.has("hide_steps") else b.map_data["hide_steps"]
	for i in steps.size():
		b._select(x)
		var allowed: Array = b._hide_allowed.keys().filter(func(p: Vector2i) -> bool: return p != x["pos"])
		var want: Array = (steps[i] as Array).map(func(s: Array) -> Vector2i: return Vector2i(s[0], s[1]))
		check(not allowed.is_empty() and allowed.all(func(p: Vector2i) -> bool: return want.has(p)), "Schritt %d: nur Verstecke erlaubt %s" % [i + 1, [allowed]])
		var target: Vector2i = allowed[0]
		x["pos"] = target
		(x["node"] as Node3D).position = b.to_world(target)
		b._hide_progress(target)
		check(b.hide_i == i + 1, "Versteck %d erreicht" % (i + 1))
		await b._flush_events()
		x["done"] = false
		b.state = Battle.State.IDLE
	check(said.count("schatten") >= 5, "Schatten spricht in mehreren Teilen: %d" % said.count("schatten"))
	check(said.find("schatten") < said.rfind("xiulan"), "Gespraech laeuft vor dem Schluss")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true], "am Professor angekommen: Mission geschafft")
	check(not b._find("maja").is_empty() and said.has("maja"), "Maja taucht auf")
	check(x.get("knocked_out", false) and (x["sprite"] as Sprite3D).billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Xiùlán ist k.o. (liegt)")
	print("ch23: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
