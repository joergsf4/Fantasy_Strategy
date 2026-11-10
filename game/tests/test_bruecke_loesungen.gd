extends SceneTree
## godot --headless --path game --script tests/test_bruecke_loesungen.gd
## Mission 12 (Zugbruecke): Den Hebel am anderen Ufer koennen auch Robinas Breitseite und der Knochenwurf des Hundsfreunds
## vom Westufer aus treffen (auch solange der Bogenschuetze am Ufer steht), damit die Mission nicht an der Gruppenwahl scheitert.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for spec in [["panzer", "breitseite"], ["hund", "knochenwurf"], ["elisabeth", "kanone"]]:
		var b := Battle.new()
		b.setup(Mission.load_mission("ch12"), defs)
		b.dialogue_runner = func(_l: Array) -> void: pass
		root.add_child(b)
		await process_frame
		var hebel := b.world.by_id("hebel")
		var river_x := 5
		b._spawn(spec[0], "p", Vector2i(9, 9))
		var u: Dictionary = b.units.back()
		var from: Vector2i = Vector2i(-1, -1)
		for y in b.grid.height:      # ein freies Feld am Westufer, von dem aus der Hebel Ziel ist
			for x in river_x:
				var p := Vector2i(x, y)
				if b.grid.cost(p, false) >= 0 and b.unit_at(p).is_empty() and not b._obj_targets(u, spec[1], p).is_empty() and from == Vector2i(-1, -1):
					from = p
		check(from != Vector2i(-1, -1), "%s trifft den Hebel vom Westufer aus" % spec[1])
		if from != Vector2i(-1, -1):
			u["pos"] = from
			b._select(u)
			b._cur_ab = spec[1]
			b._target_kind = "ability"
			b._target_objs = b._obj_targets(u, spec[1], u["pos"])
			await b._act_object(u, hebel)
			for i in 120:
				if b.world.by_id("bruecke")["state"] == "open":
					break
				await process_frame
			check(b.world.by_id("bruecke")["state"] == "open", "%s senkt die Bruecke" % spec[1])
		b.queue_free()
		await process_frame
	print("bruecke_loesungen: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
