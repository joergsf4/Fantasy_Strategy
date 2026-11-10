extends SceneTree
## godot --headless --path game --script tests/test_kein_sofort_ko.gd
## Schutz vor Sofort-K.o.: Ein Held mit vollen Leben ueberlebt jeden einzelnen gegnerischen Treffer mit 1 Leben
## (Beispiel Mission 16: Xiùláns Gebiss von hinten auf Wendy). Angeschlagene Helden fallen normal, Gegner haben keinen Schutz.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	b.setup(Mission.load_mission("ch16"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	for u in b.units.duplicate():
		b.units.erase(u)
	b._spawn("wendy", "p", Vector2i(5, 5))
	var w: Dictionary = b.units.back()
	w["dir"] = Vector2i(1, 0)
	b._spawn("xiulan", "e", Vector2i(2, 5))
	var x: Dictionary = b.units.back()
	x["atk"] = 60
	await b._run_ability(x, "gebiss", w)
	check(b.units.has(w) and int(w["hp"]) == 1, "volle Leben: Wendy ueberlebt mit 1 Leben (%d)" % int(w["hp"]))
	await b._run_ability(x, "gebiss", w)
	check(not b.units.has(w), "angeschlagen: der naechste Treffer wirft sie um")
	b._spawn("ritter", "p", Vector2i(5, 7))
	var r: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(6, 7))
	var s: Dictionary = b.units.back()
	r["atk"] = 99
	await b._strike(r, s)
	check(not b.units.has(s), "Gegner haben keinen Schutz")
	print("kein_sofort_ko: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
