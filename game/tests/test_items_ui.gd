extends SceneTree
## godot --headless --path game --script tests/test_items_ui.gd
## Gegenstaende ueber die Bedienung (Auswahl -> Gegenstand -> Ziel anklicken), auf sich selbst und auf einen Nachbarn.
## Frueher brach _begin_item mit einem Skriptfehler ab (untypisiertes [] in Array[Dictionary]): kein Gegenstand liess sich einsetzen.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for id: String in Items.consumables():
		var b := Battle.new()
		b.loadout = {"inventory": {id: 1}, "equipment": {}, "nemesis": []}
		b.setup(map, defs)
		root.add_child(b)
		await process_frame
		await process_frame
		var heroes := b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")
		var a: Dictionary = heroes[0]
		var c: Dictionary = heroes[1]
		c["pos"] = a["pos"] + Vector2i(1, 0)
		(c["node"] as Node3D).position = b.to_world(c["pos"])
		for who in ["selbst", "nachbar"]:
			for h: Dictionary in [a, c]:
				h["hp"] = 5
				Status.add(h, "poison", 3)
				h["cd"] = {"x": 2}
			b.inventory[id] = 1
			b.state = Battle.State.IDLE
			a["done"] = false
			b._select(a)
			b._click(a["pos"])
			await create_timer(0.3).timeout
			b._enter_action(false, true)
			b._begin_item(id)
			var t: Dictionary = a if who == "selbst" else c
			check(b.state == Battle.State.TARGETING and b._target_units.has(t), "%s auf %s: Ziel waehlbar" % [id, who])
			b._click(t["pos"])
			await create_timer(2.0).timeout
			check(int(b.inventory.get(id, 0)) == 0 and a["done"] and b.state == Battle.State.IDLE, "%s auf %s: verbraucht, Figur fertig" % [id, who])
			if id == "heiltrank":
				check(t["hp"] == 17, "Heiltrank auf %s: +12" % who)
		b.queue_free()
		await process_frame
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
