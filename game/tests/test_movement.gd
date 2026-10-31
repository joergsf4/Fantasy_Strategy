extends SceneTree
## godot --headless --path game --script tests/test_movement.gd
## Bewegung: Wege durch eigene Figuren, Zielwahl ohne stillen Abbruch, Klick auf den Koerper meint die Figur.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	Sfx.muted = true
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for cid in ["ch1", "ch2", "ch3", "ch4"]:
		var b := Battle.new()
		b.setup(Mission.load_mission(cid), defs)
		b.dialogue_runner = func(_l: Array) -> void: pass
		root.add_child(b)
		await process_frame
		await process_frame
		await heroes(b, cid)
		b.queue_free()
		await process_frame
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func heroes(b: Battle, cid: String) -> void:
	for u in b.units:
		if u["team"] != "p":
			continue
		b._select(u)
		# jedes erreichbare Feld hat einen lueckenlosen Weg, auch hinter eigenen Figuren
		for p: Vector2i in b.reach:
			var path := b.grid.path_to(u["pos"], p, b.reach, u["flying"])
			var ok: bool = not path.is_empty() and path[0] == u["pos"] and path[-1] == p
			for i in range(1, path.size()):
				ok = ok and Grid.dist(path[i - 1], path[i]) == 1
			check(ok, "%s %s: Weg zu %s luckenlos" % [cid, u["id"], p])
		# Ziel hinter einer eigenen Figur ist waehlbar, die Figur selbst nicht
		for o in b.units:
			if o != u and o["team"] == "p" and b.reach.has(o["pos"]):
				b.state = Battle.State.SELECTED
				b._click(o["pos"])
				check(b.state == Battle.State.SELECTED or b.sel != u, "%s: Klick auf Freund waehlt ihn oder haelt Auswahl" % cid)
				b._select(u)
				break
		# unerreichbares Feld: Auswahl bleibt, es gibt eine Begruendung
		var far := Vector2i(u["pos"].x, 0)
		if not b.reach.has(far) and b.unit_at(far).is_empty():
			b._select(u)
			b._click(far)
			check(b.state == Battle.State.SELECTED and b.sel == u, "%s %s: unerreichbares Feld bricht die Auswahl nicht ab" % [cid, u["id"]])
			check(b._why_not_reachable(far) != "", "%s: Begruendung vorhanden" % cid)
		b._cancel()
	# Klick auf den Koerper einer Figur trifft ihr Feld (nicht das Feld dahinter)
	var hero: Dictionary = b.units[0]
	var foot: Vector3 = (hero["node"] as Node3D).position + Vector3(0, 0.08, 0)
	var sp: Sprite3D = hero["sprite"]
	var mid := b.cam.unproject_position(foot + Vector3(0, sp.texture.get_height() * sp.pixel_size * 0.5, 0))
	check(b._pick_tile(mid) == hero["pos"], "%s: Klick auf den Koerper waehlt das Feld der Figur" % cid)
