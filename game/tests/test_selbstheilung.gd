extends SceneTree
## godot --headless --path game --script tests/test_selbstheilung.gd
## Heiler koennen sich selbst heilen (Aktion "Heilen" und Heilfaehigkeiten), andere Verbuendeten-Faehigkeiten (Wollmantel) nicht.
## Wollmantel haelt 3 Runden.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var abs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	check(int(abs["wollmantel"]["effects"][0]["turns"]) == 3, "Wollmantel haelt 3 Runden")
	var b := Battle.new()
	b.setup(Mission.load_mission("ch1"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	var healer: Dictionary = {}
	for id: String in defs:
		if defs[id].get("hero", false) and int(defs[id].get("heal", 0)) > 0:
			b._spawn(id, "p", Vector2i(0, 0))
			healer = b.units.back()
			break
	check(not healer.is_empty(), "ein Heiler")
	healer["hp"] = healer["maxhp"] - 5
	check(b._heal_targets(healer, healer["pos"]).has(healer), "Heilen: der Heiler kann sich selbst waehlen")
	await b._resolve(healer, healer)
	check(healer["hp"] == healer["maxhp"], "Selbstheilung wirkt")
	check(not b._heal_targets(healer, healer["pos"]).has(healer), "unverletzt: kein Ziel")
	b._spawn("wendy", "p", Vector2i(1, 0))
	var wen: Dictionary = b.units.back()
	wen["hp"] = 5
	check(not b._ab_targets(wen, "wollmantel", wen["pos"]).has(wen), "Wollmantel nicht auf sich selbst")
	for id: String in abs:
		var ab: Dictionary = abs[id]
		if ab.get("target", "") == "ally" and (ab["effects"] as Array).any(func(e: Dictionary) -> bool: return e["type"] == "heal"):
			wen["abilities"].append(id)
			check(b._ab_targets(wen, id, wen["pos"]).has(wen), "Heilfaehigkeit %s auch auf sich selbst" % id)
	for id2 in ["gruener_laser", "sternensegen", "wundersalbe", "prost"]:      # jede Heilfaehigkeit der Helden einmal auf sich selbst ausfuehren
		wen["hp"] = 5
		wen["cd"] = {}
		await b._run_ability(wen, id2, wen)
		check(int(wen["hp"]) > 5, "%s heilt den Wirker selbst" % id2)
	print("selbstheilung: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
