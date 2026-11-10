extends SceneTree
## godot --headless --path game --script tests/test_zerstoert.gd
## Zerstoerbare Objekte verschwinden, wenn sie zerstoert sind: Bienenstock (Mission 5, Waisenhaus) und Kiste.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	b.setup(Mission.load_mission("ch5"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	var hives := b.world.objects.filter(func(o: Dictionary) -> bool: return o["type"] == "hive")
	check(not hives.is_empty(), "Mission 5 hat Bienenstoecke")
	var hv: Dictionary = hives[0]
	var hp: Dictionary = b._obj_nodes[hv["id"]]
	check((hp["body"] as Node3D).visible, "Bienenstock steht")
	b.world.damage(hv, 999)
	await b._after_world_change([hv])
	check(hv["state"] == "broken" and not (hp["body"] as Node3D).visible, "zerstoerter Bienenstock ist weg")
	check(not b.grid.blocked.has(hv["pos"]) if "blocked" in b.grid else true, "Feld wieder frei")
	var cr := b.world.add_object("crate", Vector2i(1, 1), {})
	b._sync_grid()
	b._make_object(cr)
	b._refresh_object(cr, false)
	var cp: Dictionary = b._obj_nodes[cr["id"]]
	check((cp["body"] as Node3D).visible, "Kiste steht")
	b.world.damage(cr, 999)
	await b._after_world_change([cr])
	check(cr["state"] == "broken" and not (cp["body"] as Node3D).visible, "zerstoerte Kiste ist weg")
	print("zerstoert: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
