extends SceneTree
## godot --headless --path game --script tests/test_regent_schnee.gd
## Kapitel 18 "Der Regent im Schnee": keine Feinde zu Beginn (kein Sofortsieg), Naehern an die Huette loest den Regenten und Robowart mit den Frischlingen aus,
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
	var m := Mission.load_mission("ch18")
	check(m["goals"][0]["type"] == "rout_spawned" and str(m["lose_if_fallen"]) == "fuerst_lumpen", "Ziel und Niederlagenregel")
	check(m.has("interlude_before") and m["interlude_before"]["scene"] == "snow", "Zwischensequenz im Schneesturm vor der Mission")
	for id: String in ["fuerst_lumpen", "cyborg_wart", "frischlinge"]:
		check(defs.has(id), "Einheit %s existiert" % id)
	for e in ["fuerst_lumpen", "fuerst_lumpen_weinerlich"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % e), "Portrait %s" % e)
	check(ResourceLoader.exists("res://assets/tokens/fuerst_lumpen.png") and ResourceLoader.exists("res://assets/fx/fx_huette.png"), "Karten-Bilder von Regent und Huette")
	var fixed := Mission.dialogue_ids("ch18")
	check(fixed.has("maedchen_baer") and fixed.has("hund") and not fixed.has("ritter") and not fixed.has("wendy"), "feste Figuren: %s" % [fixed])
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
	# Held naehert sich der Huette (Huette bei (1,3), Abstand 5)
	var mira := b._find("maedchen_baer")
	mira["pos"] = Vector2i(4, 5)
	await b._flush_events()
	check(not b._find("fuerst_lumpen").is_empty() and b._find("fuerst_lumpen")["team"] == "p", "Der Regent tritt als Schuetzling auf")
	check(b._count_team("e") == 3 and b._find("cyborg_wart").size() > 0, "Robowart und zwei Frischlinge erscheinen")
	check(said.has("fuerst_lumpen") and said.has("cyborg_wart") and said.has("frischlinge"), "Dialoge gelaufen: %s" % [said])
	check(Mission.goal_text(b.goal, 3, 1, b._capture_info()).contains("3 übrig") and not b.goal_met(), "Ziel jetzt: Gegner besiegen")
	# Faellt der Regent, ist die Mission verloren
	var regent := b._find("fuerst_lumpen")
	regent["hp"] = 1
	await b._deal(regent, 99, "")
	await b._check_end()
	check(got == [false], "Regent gefallen: Mission verloren (%s)" % [got])
	print("regent_schnee: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
