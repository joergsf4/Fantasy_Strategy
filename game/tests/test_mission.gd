extends SceneTree
## godot --headless --path game --script tests/test_mission.gd
## Missionsformat: Ziele (rout, survive, reach), Niederlage, Ausloeser (Runde, Feld) mit Verstaerkung und Dialog.

var fails := 0
var b: Battle
var map: Dictionary
var defs: Dictionary
var lines_seen: Array = []
var finished_with: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	map = Mission.load_mission("ch1")
	check(map["rows"].size() == 10 and map["goals"][0]["type"] == "rout" and map["triggers"].size() >= 1, "Mission ch1 geladen: Karte, Ziel, Ausloeser")
	check(map["title"] == "Eichenfurt brennt" and map.has("briefing") and map.has("chests"), "Mission ch1 enthaelt Titel, Briefing und Kartenfelder")
	var m2 := map.duplicate(true)
	m2["players"] = []
	m2["enemies"] = []
	m2["triggers"] = [
		{"when": {"turn": 3}, "do": [{"popup": "Verstaerkung!"}, {"dialogue": [{"speaker": "x", "text": "hallo"}]}, {"spawn": [{"id": "soldat_infanterie", "pos": [9, 7]}, {"id": "soldat_beritten", "pos": [9, 7]}]}]},
		{"when": {"enter": [6, 6]}, "do": [{"spawn": [{"id": "soldat_infanterie", "pos": [9, 2], "carry": {"items": {"heiltrank": 1}}}]}]}]
	b = Battle.new()
	b.setup(m2, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		lines_seen.append(lines)
	b.finished.connect(func(won: bool) -> void: finished_with.append(won))
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func clear() -> void:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE


func run_tests() -> void:
	# Ziel-Texte
	check(Mission.goal_text({"type": "rout"}, 3, 1) == "Ziel: Besiegt alle Gegner (3 übrig)", "Text rout")
	check(Mission.goal_text({"type": "survive", "turns": 5}, 2, 7) == "Ziel: Haltet durch (Runde 5 von 5)", "Text survive, gedeckelt")
	# rout
	b._spawn("ritter", "p", Vector2i(1, 8))
	b._spawn("soldat_infanterie", "e", Vector2i(8, 8))
	check(not b.goal_met(), "rout: Gegner uebrig -> nicht erreicht")
	b.units.erase(b.units[1])
	check(b.goal_met(), "rout: keine Gegner -> erreicht")
	# survive
	b.goal = {"type": "survive", "turns": 2}
	b.turn = 2
	check(not b.goal_met(), "survive 2: Runde 2 noch nicht")
	b.turn = 3
	check(b.goal_met(), "survive 2: ab Runde 3 erreicht")
	# reach
	b.goal = {"type": "reach", "tile": [4, 4]}
	check(not b.goal_met(), "reach: Held steht nicht auf dem Feld")
	b.units[0]["pos"] = Vector2i(4, 4)
	check(b.goal_met(), "reach: Held auf dem Feld")
	b.units[0]["pos"] = Vector2i(1, 8)
	# Ausloeser Runde: feuert einmal, Dialog laeuft, Verstaerkung auf freien Feldern
	b.goal = {"type": "rout"}
	var n0 := b.units.size()
	await b._run_triggers("turn", 2)
	check(b.units.size() == n0, "Runde 2: nichts passiert")
	await b._run_triggers("turn", 3)
	check(b.units.size() == n0 + 2, "Runde 3: zwei Verstaerkungen, war %d -> %d" % [n0, b.units.size()])
	check(lines_seen.size() == 1 and lines_seen[0][0]["text"] == "hallo", "Dialog wurde angezeigt")
	var pos_a: Vector2i = b.units[n0]["pos"]
	var pos_b: Vector2i = b.units[n0 + 1]["pos"]
	check(pos_a != pos_b and pos_a == Vector2i(9, 7), "Zweite Verstaerkung weicht auf freies Feld aus (%s, %s)" % [pos_a, pos_b])
	check(b.units[n0]["team"] == "e", "Verstaerkung ist Gegner")
	await b._run_triggers("turn", 3)
	check(b.units.size() == n0 + 2 and lines_seen.size() == 1, "Ausloeser feuert nur einmal")
	# Ausloeser Feld betreten, mit Beute-Traeger
	await b._run_triggers("enter", Vector2i(2, 2))
	check(b.units.size() == n0 + 2, "Falsches Feld: nichts")
	await b._run_triggers("enter", Vector2i(6, 6))
	var last: Dictionary = b.units.back()
	check(b.units.size() == n0 + 3 and not (last["carry"] as Dictionary).is_empty(), "Feld (6,6): Verstaerkung mit Beute")
	# Niederlage: alle Helden weg
	clear()
	b._spawn("soldat_infanterie", "e", Vector2i(8, 8))
	await b._check_end()
	check(finished_with == [false] and b.state == Battle.State.OVER, "Alle Helden gefallen -> Niederlage")
	# Sieg ueber Ziel
	b.state = Battle.State.IDLE
	finished_with.clear()
	clear()
	b._spawn("ritter", "p", Vector2i(4, 4))
	b.goal = {"type": "reach", "tile": [4, 4]}
	await b._check_end()
	check(finished_with == [true], "reach erreicht -> Sieg trotz lebender Gegner (keine Gegner noetig)")
