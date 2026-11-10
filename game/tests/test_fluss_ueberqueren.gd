extends SceneTree
## godot --headless --path game --script tests/test_fluss_ueberqueren.gd
## Mission 12 (Zugbruecke): Ohne Bruecke kommt man auch so ueber den Fluss: Muskelaugust wirft einen Helden ans Ostufer,
## Lin springt mit dem Stabsprung ueber die hochgezogene Bruecke.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	b.setup(Mission.load_mission("ch12"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	for e in b.units.filter(func(x: Dictionary) -> bool: return x["team"] == "e"):
		b.units.erase(e)
	var river_x := 5
	# Wurf: Muskelaugust wirft Lin ans Ostufer
	b._spawn("museklaugust", "p", Vector2i(3, 2))
	var aug: Dictionary = b.units.back()
	b._spawn("kungfu", "p", Vector2i(4, 2))
	var lin: Dictionary = b.units.back()
	check(b._ab_targets(aug, "wurf", aug["pos"]).has(lin), "Muskelaugust kann Lin greifen")
	var east := b._landing_tiles_for(lin).filter(func(p: Vector2i) -> bool: return p.x > river_x)
	check(not east.is_empty(), "Wurf: Landefelder am Ostufer")
	b.sel = aug
	b._landing_ally = lin
	b._cur_ab = "wurf"
	await b._do_throw_ally(east[0])
	check(int(lin["pos"].x) > river_x, "Lin ist am Ostufer gelandet: %s" % [lin["pos"]])
	# Stabsprung: Lin springt ueber die hochgezogene Bruecke
	var br := b.world.by_id("bruecke")
	check(br["state"] == "up", "Bruecke ist hochgezogen")
	lin["pos"] = br["pos"] + Vector2i(-1, 0)
	(lin["node"] as Node3D).position = b.to_world(lin["pos"])
	lin["done"] = false
	var tg := b._obj_targets(lin, "stabsprung", lin["pos"])
	check(tg.has(br), "Stabsprung: die hochgezogene Bruecke ist Sprungziel")
	b._select(lin)
	b._cur_ab = "stabsprung"
	b._target_kind = "ability"
	b._target_objs = tg
	await b._act_object(lin, br)
	check(int(lin["pos"].x) > river_x, "Lin ist ueber den Fluss gesprungen: %s" % [lin["pos"]])
	print("fluss_ueberqueren: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
