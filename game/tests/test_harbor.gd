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
	check(not goal.has("all"), "ein Held genuegt am Zielfeld")
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
	# Ziel: ein Held auf dem goldenen Feld genuegt, das Feld ist anfangs von Wachen besetzt
	check(not b.goal_met(), "Ziel anfangs nicht erreicht")
	check(not b.unit_at(gt).is_empty() and b.unit_at(gt)["team"] == "e", "auf dem Zielfeld steht anfangs eine Wache")
	b.units.erase(b.unit_at(gt))
	b._find("hund")["pos"] = gt
	check(b.goal_met(), "ein Held auf dem Zielfeld erreicht das Schiff")
	# Hafentor-Sperre: Spalte x = 6 hat genau eine Luecke (y = 5)
	var blocked_col := 0
	for y in b.grid.height:
		if b.grid.blocked.has(Vector2i(6, y)):
			blocked_col += 1
	check(blocked_col == b.grid.height - 1 and not b.grid.blocked.has(Vector2i(6, 5)), "Kisten-Sperre mit genau einer Luecke bei y = 5")
	# Wart wartet in Runde 3 sicher auf dem Steg, auch ohne Vorgeschichte; die Trainingspuppe ist nicht mehr dabei
	var b3 := Battle.new()
	b3.setup(Mission.load_mission("ch6"), defs)
	b3.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b3)
	await process_frame
	check(b3._find("wart").is_empty() and b3._find("dummy").is_empty(), "zu Beginn weder Wart noch Puppe")
	b3.turn = 3
	await b3._run_triggers("turn", 3)
	var wart: Dictionary = b3._find("wart")
	check(not wart.is_empty() and wart["pos"].x >= 6, "Wart erscheint in Runde 3 auf dem Kai/Steg")
	b3.turn = 4
	await b3._run_triggers("turn", 4)
	check(b3._find("dummy").is_empty(), "Runde 4: keine Trainingspuppe")
	var before: int = b3._count_team("e")
	b3.turn = 5
	await b3._run_triggers("turn", 5)
	check(b3._count_team("e") == before + 2, "Runde 5: zwei Mann Verstaerkung per Beiboot")
	var harbor := true
	for e in b3.units:
		if e["team"] == "e" and e["id"] == "soldat_infanterie" and e["pos"].y >= 7 and e["pos"].x < 7:
			harbor = false
	check(harbor, "Verstaerkung kommt vom Hafen (rechts unten), nicht vom Stadttor")
	# Simulator: Reach-Ziel und Breitseite
	var sb := SimSetup.build({"map": "ch6", "players": [], "enemies": []}, 7)
	check(sb.goal_tile == gt, "Simulator kennt das Zielfeld")
	var late_ids: Array = sb.late.map(func(l: Dictionary) -> String: return l["id"])
	check(late_ids.has("wart") and not late_ids.has("dummy") and late_ids.count("soldat_infanterie") == 2, "Simulator spawnt Wart und Beiboot (ohne Vorgeschichte), keine Puppe")
	var seen := 0
	for u in sb.units:
		if u["team"] == "p" and (u["abilities"] as Array).has("breitseite"):
			seen += 1
	check(seen == 1, "Simulator gewaehrt Elisabeth die Breitseite")
	var w := sb.play(20)
	check(w in ["p", "e", "timeout"], "Simulationslauf laeuft durch (%s)" % w)


func grid_ok(p: Vector2i) -> bool:
	return b.grid.inside(p) and b.unit_at(p).is_empty() and b.grid.cost(p) >= 0
