extends SceneTree
## godot --headless --path game --script tests/test_labor.gd
## Kapitel 13 "Das Labor im Wald": drei Kinder befreien (free_all), Energiemaschine schockt Helden daneben, Professor flieht, Bonus Maschine zerstoert.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch13")
	check(m["goals"][0]["type"] == "free_all", "Ziel: alle befreien")
	for id: String in Mission.dialogue_ids("ch13"):
		check(defs.has(id) or id == "waisenkinder", "Sprecher %s existiert" % id)
	for id in ["kugelblitz", "kugelblitz_lachend", "kugelblitz_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Portrait %s" % id)
	check(ResourceLoader.exists("res://assets/tokens/kugelblitz.png") and ResourceLoader.exists("res://assets/fx/fx_maschine.png"), "Karten-Figur und Maschine")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	await process_frame
	check(not b.goal_met(), "Anfangs sind die Kinder gefesselt")
	# Maschine schockt Helden direkt daneben
	var hero := b._find("hund")
	hero["pos"] = Vector2i(7, 5)      # neben der Maschine (8,5)
	var hp0: int = hero["hp"]
	b._actor = {}
	await b._machine_phase()
	check(hero["hp"] == hp0 - 5, "Zap: 5 Schaden neben der Maschine (%d -> %d)" % [hp0, hero["hp"]])
	hero["pos"] = Vector2i(2, 5)
	var hp1: int = hero["hp"]
	await b._machine_phase()
	check(hero["hp"] == hp1, "Weit weg: kein Schaden")
	# Kinder befreien
	for id in ["kind1", "kind2"]:
		b.world.by_id(id)["state"] = "free"
	check(not b.goal_met(), "Zwei von drei befreit: noch nicht geschafft")
	b.world.by_id("kind3")["state"] = "free"
	check(b.goal_met(), "Alle drei frei: Ziel erreicht")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true] and said.has("kugelblitz") and said.has("waisenkinder"), "Abschlussszenen: %s" % [said])
	check(b.retreated.has("kugelblitz"), "Professor zieht sich zurueck")
	check(b.results()["objectives"][1]["done"] == false, "Maschine noch heil: kein Bonus")
	b.world.by_id("maschine")["state"] = "broken"
	b._results.clear()
	check(b.results()["objectives"][1]["done"] == true, "Maschine zerstoert: Bonus")
	print("labor: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
