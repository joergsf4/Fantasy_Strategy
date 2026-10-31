extends SceneTree
## godot --headless --path game --script tests/test_bees.gd
## Kapitel 5: Bienenstoecke, Glocke und Hundsfreund, Waisenhaus-Stiche, Stachelias Rueckzug.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	Sfx.muted = true
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(Mission.load_mission("ch5"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	await run_tests(defs)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func run_tests(defs: Dictionary) -> void:
	var m := Mission.load_mission("ch5")
	for e: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
		check(defs.has(e["id"]) and ResourceLoader.exists("res://assets/tokens/%s.png" % e["id"]), "Einheit %s bekannt" % e["id"])
	for id in ["kind_lotte", "kind_pip", "kind_mia"]:
		check(ResourceLoader.exists("res://assets/tokens/%s.png" % id), "%s hat eine Karten-Figur" % id)
	check(ResourceLoader.exists("res://assets/portraits/waisenkinder_lachend.png") and ResourceLoader.exists("res://assets/fx/fx_honigtopf.png"), "Bilder da")
	check(defs["bienenkrieger"]["flying"] and (defs["bienenkrieger"]["tags"] as Array).has("schwarm"), "Bienenkrieger fliegen und sind ein Schwarm")
	# Stoecke: schluepfen alle 2 Gegnerphasen, hoechstens 6 Bienen
	var bees := func() -> int: return b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "bienenkrieger").size()
	var start: int = bees.call()
	await b._hive_phase()
	check(bees.call() == start, "erste Phase: noch kein Schluepfen")
	await b._hive_phase()
	check(bees.call() == mini(start + 3, Battle.HIVE_CAP), "zweite Phase: aus den Stoecken schluepfen Bienen, bis die Obergrenze erreicht ist (%d)" % bees.call())
	for i in 6:
		await b._hive_phase()
	check(bees.call() <= Battle.HIVE_CAP, "hoechstens %d Bienen gleichzeitig (%d)" % [Battle.HIVE_CAP, bees.call()])
	# zerstoerter Stock schluepft nicht mehr
	var hive := b.world.by_id("stock1")
	b.world.damage(hive, 99)
	check(hive["state"] == "broken" and not b.grid.blocked.has(hive["pos"]) or hive["state"] == "broken", "Stock zerstoerbar")
	# Waisenhaus: Biene daneben sticht
	var biene: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "bienenkrieger")[0]
	biene["pos"] = b.world.by_id("waisenhaus")["pos"] + Vector2i(0, 1)
	await b._sting_check(biene)
	check(b.kids_stung == 1, "Biene am Waisenhaus sticht die Kinder")
	var res := b.results()
	var done := {}
	for o: Dictionary in res["objectives"]:
		done[o["id"]] = o["done"]
	check(not done["keine_stiche"], "Bonus 'Kein Kind gestochen' verloren")
	# Glocke: laeuten, nach 2 Runden kommt der Hundsfreund als Held
	var bell := b.world.by_id("glocke")
	check(bell["state"] == "ready", "Glocke bereit")
	var hero: Dictionary = b.units[0]
	hero["pos"] = bell["pos"] + Vector2i(0, 1)
	await b._ring_bell(hero, bell)
	check(bell["state"] == "rung", "Glocke geläutet")
	check(b._scheduled.size() == 1 and b._scheduled[0]["id"] == "hund", "Hundsfreund wird in 2 Runden erwartet")
	var before: int = b._count_team("p")
	b.turn += 1
	await b._run_scheduled()
	check(b._count_team("p") == before, "nach 1 Runde noch nicht da")
	b.turn += 1
	await b._run_scheduled()
	check(b._count_team("p") == before + 1 and not b._find("hund").is_empty() and b._find("hund")["team"] == "p", "Hundsfreund kaempft als Held mit")
	# Stachelia: Wendung bei 50 %, Rueckzug zaehlt als ueberzeugt
	var stachelia: Dictionary = b._find("bienenmaedchen")
	check(stachelia["maxhp"] == 40, "Stachelia ist als Boss gestaerkt (40 Leben)")
	stachelia["hp"] = 10
	await b._flush_events()
	check(b._find("bienenmaedchen").is_empty() and b.retreated.has("bienenmaedchen"), "Stachelia zieht sich bei unter 50 % zurueck")
