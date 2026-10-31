extends SceneTree
## godot --headless --path game --script tests/test_hostage.gd
## Mission 4 "Das Teehaus am Pass": Geisel befreien, Luermuhr, Xiulan (Gebiss, Rueckzug), Wiederkehr.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(Mission.load_mission("ch4"), defs)
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	await process_frame
	await run_tests(defs)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func run_tests(defs: Dictionary) -> void:
	for cid in ["ch4"]:
		var m := Mission.load_mission(cid)
		for e: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
			check(defs.has(e["id"]) and ResourceLoader.exists("res://assets/tokens/%s.png" % e["id"]), "Einheit %s bekannt" % e["id"])
	check(ResourceLoader.exists("res://assets/tokens/mutter.png") and ResourceLoader.exists("res://assets/fx/fx_gebiss.png"), "Bilder da")
	check(b.goal.get("type") == "free", "Ziel: Geisel befreien")
	check(not b.goal_met(), "Ziel anfangs nicht erreicht")
	var g := b.world.by_id("geisel")
	check(g["state"] == "bound" and b.grid.blocked.has(g["pos"]), "Geisel gefesselt, Feld gesperrt")
	check(b.grid.blocked.has(b.world.by_id("teehaus")["pos"]), "Teehaus sperrt sein Feld")
	# Held auf Nachbarfeld darf befreien, ein ferner nicht
	var hero: Dictionary = b.units[0]
	var far: Vector2i = hero["pos"]
	check(b._hostage_near(far).is_empty(), "weit weg: kein Befreien")
	check(not b._hostage_near(g["pos"] + Vector2i(1, 0)).is_empty() and not b._hostage_near(g["pos"] + Vector2i(0, 1)).is_empty(), "nebenan: Befreien moeglich")
	hero["pos"] = g["pos"] + Vector2i(0, 1)
	# Wachen neben der Geisel: Befreien gesperrt
	check(b._hostage_guards(g) == 2, "zwei Wachen stehen neben der Geisel")
	check(not b._hostage_option(g)["enabled"], "Befreien gesperrt, solange Wachen daneben stehen")
	var guards: Array = b.units.filter(func(e: Dictionary) -> bool: return e["team"] == "e" and Grid.dist(e["pos"], g["pos"]) == 1)
	check(guards.all(func(e: Dictionary) -> bool: return e["guard"]), "Wachen sind als Wache markiert")
	var parked: Array = []
	for e: Dictionary in guards:
		parked.append(e["pos"])
		e["pos"] = Vector2i(11, 9)
	check(b._hostage_option(g)["enabled"], "ohne Wachen kann man die Fesseln loesen")
	# Runde 1: Fesseln anritzen, noch nicht frei, in derselben Runde nicht abschliessbar
	await b._free_hostage(hero, g)
	check(g["state"] == "bound" and g["progress"] == 1, "erste Aktion ritzt nur an")
	check(not b._hostage_option(g)["enabled"], "in derselben Runde kein Abschluss")
	# niemand mehr bei ihr: die Fesseln ziehen sich wieder zu
	hero["pos"] = Vector2i(0, 9)
	await b._retie_check()
	check(g["progress"] == 0, "ohne Helden neben ihr geht der Fortschritt verloren")
	hero["pos"] = g["pos"] + Vector2i(0, 1)
	await b._free_hostage(hero, g)
	b.turn += 1
	await b._retie_check()
	check(g["progress"] == 1 and b._hostage_option(g)["enabled"], "naechste Runde mit Held daneben: Abschluss moeglich")
	await b._free_hostage(hero, g)
	check(g["state"] == "free" and not b.grid.blocked.has(g["pos"]), "Geisel frei, Feld wieder offen")
	check(b.goal_met(), "Ziel erreicht nach Befreien")
	for i in guards.size():
		(guards[i] as Dictionary)["pos"] = parked[i]
	# Wache ruehrt sich nicht, bis ein Held auf 3 Felder herankommt
	var wache: Dictionary = guards[0]
	hero["pos"] = Vector2i(0, 9)
	check(not b._alarm(wache) and wache["guard"], "Held weit weg: Wache bleibt stehen")
	hero["pos"] = wache["pos"] + Vector2i(0, 3)
	check(b._alarm(wache) and not wache["guard"], "Held nah: Wache wird aktiv und bleibt es")
	# Gebiss: Fernangriff mit Abklingzeit
	var xi: Dictionary = b._find("xiulan")
	check(not xi.is_empty() and xi["abilities"].has("gebiss"), "Xiulan hat Gebiss-Wurf")
	var ab: Dictionary = b.abilities["gebiss"]
	check(int(ab["range"][0]) == 2 and int(ab["range"][1]) == 4 and int(ab["cd"]) == 3, "Gebiss: Reichweite 2-4, Abklingzeit 3")
	check(defs["xiulan"].get("flees", false), "Xiulan flieht statt zu sterben")
	# Rueckzug (Wendung) zaehlt als ueberzeugt und merkt sie sich
	await b._fire({"do": [{"retreat": "xiulan"}]})
	check(b._find("xiulan").is_empty() and b.retreated == ["xiulan"] and b.fled == ["xiulan"], "Xiulan zieht sich zurueck")
	var res := b.results()
	var done := {}
	for o: Dictionary in res["objectives"]:
		done[o["id"]] = o["done"]
	check(done["ueberzeugt"] and not done["alle_gegner"], "Bonus 'ueberzeugt' erfuellt, 'alle Wachen' nicht")
	# Luermuhr: Verstaerkung in Runde 2
	var before := b._count_team("e")
	await b._run_triggers("turn", 2)
	check(b._count_team("e") == before + 1, "Runde 2: Verstaerkung durch das Baby-Geschrei")
