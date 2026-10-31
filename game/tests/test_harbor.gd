extends SceneTree
## godot --headless --path game --script tests/test_harbor.gd
## Kapitel 6: Hafenstadt, Holzsteg, Schiff, Breitseite, Zielfeld, Wart-Rueckkehr, Simulator.

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
	var m := Mission.load_mission("ch6")
	b.setup(m, defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	await run_tests(defs, m)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func run_tests(defs: Dictionary, m: Dictionary) -> void:
	for e: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
		check(defs.has(e["id"]) and ResourceLoader.exists("res://assets/tokens/%s.png" % e["id"]), "Einheit %s bekannt" % e["id"])
	check(ResourceLoader.exists("res://assets/fx/fx_schiff.png"), "Schiff-Sprite da")
	var ids: Array = (m["players"] as Array).map(func(p: Dictionary) -> String: return p["id"])
	check(ids.size() == 6 and ids.has("robo") and ids.has("hund") and ids.has("elisabeth") and not ids.has("wendy"), "Gruppe: Robo als Heiler, Hundsfreund dabei, Wendy nicht")
	# Steg: laufbar, Zielfeld liegt auf dem Steg
	var goal: Dictionary = m["goals"][0]
	var gt := Vector2i(goal["tile"][0], goal["tile"][1])
	check(goal["type"] == "reach" and b.grid.terrain(gt) == "P" and b.grid.cost(gt) == 1, "Zielfeld ist ein begehbarer Steg")
	check(goal.get("all", false) and int(goal["within"]) == 3, "alle Helden muessen zum Schiff")
	check(b.grid.terrain(Vector2i(10, 6)) == "W" and b.grid.cost(Vector2i(10, 6)) < 0, "Wasser neben dem Steg ist nicht begehbar")
	# Breitseite: nur Elisabeth, Reichweite 3-9, Abklingzeit 3
	var eli: Dictionary = b._find("elisabeth")
	check((eli["abilities"] as Array).has("breitseite"), "Elisabeth hat die Breitseite")
	check(not (b._find("ritter")["abilities"] as Array).has("breitseite"), "andere Figuren nicht")
	var ab: Dictionary = b.abilities["breitseite"]
	check(int(ab["range"][0]) == 3 and int(ab["range"][1]) == 9 and int(ab["cd"]) == 3, "Breitseite: Reichweite 3-9, Abklingzeit 3")
	var foe: Dictionary = b._find("soldat_infanterie")
	var tgt: Array = b._ab_targets(eli, "breitseite", eli["pos"])
	check(tgt.has(foe) or not tgt.is_empty(), "Breitseite findet Ziele in der Hafenstadt")
	var hp0: int = foe["hp"]
	eli["pos"] = foe["pos"] - Vector2i(5, 0) if grid_ok(foe["pos"] - Vector2i(5, 0)) else eli["pos"]
	await b._run_ability(eli, "breitseite", foe)
	check(foe["hp"] < hp0 or not b.units.has(foe), "Breitseite trifft")
	check(int(eli["cd"].get("breitseite", 0)) > 0, "Breitseite ist danach in Abklingzeit")
	# Kiste zerbricht
	var kiste := b.world.by_id("kiste1")
	check(b.grid.blocked.has(kiste["pos"]), "Kiste sperrt das Feld")
	b.world.damage(kiste, 99)
	b.grid.blocked = b.world.blocked()
	check(kiste["state"] == "broken" and not b.grid.blocked.has(kiste["pos"]), "zerstoerte Kiste gibt das Feld frei")
	# Ziel: erst wenn alle Helden am Schiff sind
	check(not b.goal_met(), "Ziel anfangs nicht erreicht")
	b._find("hund")["pos"] = gt
	check(not b.goal_met(), "ein Held allein reicht nicht")
	var spots: Array[Vector2i] = [Vector2i(8, 6), Vector2i(7, 6), Vector2i(8, 5), Vector2i(8, 7), Vector2i(7, 5)]
	var i := 0
	for u in b.units:
		if u["team"] == "p" and u["id"] != "hund":
			u["pos"] = spots[i]
			i += 1
	check(b.goal_met(), "alle Helden am Schiff: Ziel erreicht")
	# Wart nur mit Vorgeschichte
	var b2 := Battle.new()
	b2.setup(Mission.load_mission("ch6"), defs)
	b2.loadout = {"nemesis": ["wart"]}
	b2.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b2)
	await process_frame
	check(b2._cond_ok({"fled": ["wart"]}), "mit Vorgeschichte ist Wart bekannt")
	b2.turn = 3
	await b2._run_triggers("turn", 3)
	check(not b2._find("wart").is_empty(), "Wart erscheint in Runde 3 auf dem Kai")
	check(not b._cond_ok({"fled": ["wart"]}), "ohne Vorgeschichte kein Wart")
	# Simulator: Reach-Ziel und Breitseite
	var sb := SimSetup.build({"map": "ch6", "players": [], "enemies": []}, 7)
	check(sb.goal_tile == gt, "Simulator kennt das Zielfeld")
	var seen := 0
	for u in sb.units:
		if u["team"] == "p" and (u["abilities"] as Array).has("breitseite"):
			seen += 1
	check(seen == 1, "Simulator gewaehrt Elisabeth die Breitseite")
	var w := sb.play(20)
	check(w in ["p", "e", "timeout"], "Simulationslauf laeuft durch (%s)" % w)


func grid_ok(p: Vector2i) -> bool:
	return b.grid.inside(p) and b.unit_at(p).is_empty() and b.grid.cost(p) >= 0
