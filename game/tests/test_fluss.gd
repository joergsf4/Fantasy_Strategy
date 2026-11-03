extends SceneTree
## godot --headless --path game --script tests/test_fluss.gd
## Kapitel 12 "Die hochgezogene Bruecke": Zugbruecke sperrt den Fluss, der Hebel (Fernkampf oder daneben stehen) laesst sie herunter.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch12")
	for id: String in Mission.dialogue_ids("ch12"):
		check(defs.has(id), "Sprecher %s existiert" % id)
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	await process_frame
	var br := b.world.by_id("bruecke")
	check(br["state"] == "up" and b.world.is_blocking(br), "Zugbruecke ist hochgeklappt und sperrt")
	check(b.grid.cost(Vector2i(5, 5), false) == -1 and b.grid.cost(Vector2i(5, 4), false) == -1, "Fluss ist fuer Fussvolk unpassierbar")
	check(b.grid.cost(Vector2i(5, 4), true) == 1, "Flieger kommen hinueber")
	check(not b.grid.reachable(Vector2i(4, 5), 20).has(Vector2i(7, 5)), "Kein Weg ueber den Fluss ohne Bruecke")
	# Hebel treffen (Kanone, ranged_hit)
	var sw := b.world.by_id("hebel")
	check(sw["state"] == "off" and sw["link"] == ["bruecke"], "Hebel verknuepft mit der Bruecke")
	var eli := b._find("elisabeth")
	eli["pos"] = Vector2i(4, 5)
	var sol := b.world.solution(sw, ["ranged_hit"])
	check(sol.get("effect", "") == "toggle", "Fernkampf legt den Hebel um")
	await b._after_world_change(b.world.apply(sw, "toggle"))
	check(br["state"] == "open" and not b.world.is_blocking(br), "Zugbruecke ist heruntergelassen")
	check(b.grid.cost(Vector2i(5, 5), false) == 1, "Brueckenfeld ist begehbar")
	check(b.grid.reachable(Vector2i(4, 5), 20).has(Vector2i(7, 5)), "Weg ueber die Bruecke")
	print("fluss: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
