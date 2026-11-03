extends SceneTree
## godot --headless --path game --script tests/test_drunken_pos.gd
## Nach dem Drunken Strike steht Lin wieder genau auf seinem Feld.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch1")
	m["enemies"] = []
	var b := Battle.new()
	b.setup(m, defs)
	root.add_child(b)
	await process_frame
	for u in b.units.duplicate():
		b.units.erase(u)
		(u["node"] as Node3D).queue_free()
	b._spawn("kungfu", "p", Vector2i(4, 7))
	var lin: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(5, 7))
	var foe: Dictionary = b.units.back()
	foe["hp"] = 400
	foe["maxhp"] = 400
	Status.add(lin, "betrunken", 3)
	await b._run_ability(lin, "drunken_strike", foe)
	await create_timer(1.0).timeout
	var home := b.to_world(lin["pos"])
	var d := ((lin["node"] as Node3D).position - home).length()
	check(d < 0.01, "Lin steht auf seinem Feld (Abweichung %.3f)" % d)
	print("drunken_pos: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
