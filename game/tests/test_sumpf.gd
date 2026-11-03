extends SceneTree
## godot --headless --path game --script tests/test_sumpf.gd
## Mission 15: Sumpf-Biom (Gelaende S: Bewegung 2, Sumpfgas), Stachelia in der Gruppe, Cyborg-Wart und Frischlinge. Mission 14: Abschlussszene mit Lieselotte.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch15")
	check(m.get("biome", "") == "sumpf" and (m["rows"] as Array).any(func(r: String) -> bool: return r.contains("S")), "Karte im Sumpf-Biom mit Sumpffeldern")
	check((m["players"] as Array).any(func(p: Dictionary) -> bool: return p["id"] == "bienenmaedchen"), "Stachelia ist in Mission 15 in der Gruppe")
	check(Party.roster(defs, 15, true).has("bienenmaedchen"), "Stachelia ist ab Mission 15 waehlbar")
	for id: String in Mission.dialogue_ids("ch15") + Mission.dialogue_ids("ch14"):
		check(defs.has(id) or id == "waisenkinder" or id == "mutter", "Sprecher %s existiert" % id)
	check(Grid.TERRAIN["S"]["cost"] == 2, "Sumpf kostet doppelte Bewegung")
	for id in ["fx_totbaum", "fx_schilf", "fx_sumpfpilz"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % id), "Sprite %s" % id)
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	await process_frame
	check(b.terrain.biome == "sumpf" and not b._find("cyborg_wart").is_empty() and not b._find("frischlinge").is_empty(), "Gelaende kennt das Biom, Cyborg-Wart und Frischlinge sind da")
	# Sumpfgas: wer zu Beginn seiner Phase im Morast steht, bekommt 3 Schaden; Flieger und Gras nicht
	var hero := b._find("hund")
	var swamp_tile := Vector2i(-1, -1)
	var dry_tile := Vector2i(-1, -1)
	for y in b.grid.height:
		for x in b.grid.width:
			var t := b.grid.terrain(Vector2i(x, y))
			if t == "S" and swamp_tile.x < 0 and b.unit_at(Vector2i(x, y)).is_empty():
				swamp_tile = Vector2i(x, y)
			if t == "G" and dry_tile.x < 0 and y > 7 and b.unit_at(Vector2i(x, y)).is_empty():
				dry_tile = Vector2i(x, y)
	hero["pos"] = swamp_tile
	var hp0: int = hero["hp"]
	await b._begin_phase("p")
	check(hero["hp"] == hp0 - int(m["sumpf_dmg"]), "Sumpfgas: %d Schaden im Morast (%d -> %d)" % [int(m["sumpf_dmg"]), hp0, hero["hp"]])
	var wasp := b._find("bienenmaedchen")
	wasp["pos"] = swamp_tile + Vector2i(1, 0) if b.grid.terrain(swamp_tile + Vector2i(1, 0)) == "S" else swamp_tile
	var wasp_hp: int = wasp["hp"]
	hero["pos"] = dry_tile
	var hp1: int = hero["hp"]
	await b._begin_phase("p")
	check(hero["hp"] == hp1 and wasp["hp"] == wasp_hp, "Festes Gelaende und Flieger (Stachelia) bleiben verschont")
	# Mission 15: keine Berge im Norden mehr, Mission 16: Streit um den Sold, zwei Truhen schicken Xiulan weg
	check(not (m["rows"] as Array).any(func(r: String) -> bool: return r.contains("M")) and not m.has("walls"), "Mission 15: keine Berge im Norden")
	var m16 := Mission.load_mission("ch16")
	for id: String in Mission.dialogue_ids("ch16"):
		check(defs.has(id), "Sprecher %s existiert (Mission 16)" % id)
	check((m16["chests"] as Array).size() == 2 and (m16["no_flee"] as Array).has("xiulan"), "Mission 16: zwei Truhen, Xiulan flieht nicht von selbst")
	said.clear()
	var b2 := Battle.new()
	b2.setup(m16, defs)
	b2.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b2)
	await process_frame
	check(not b2._find("xiulan").is_empty() and not b2._find("kugelblitz").is_empty(), "Kugelblitz und Xiulan auf der Karte")
	b2.chests[0]["open"] = true
	await b2._flush_events()
	check(not b2._find("xiulan").is_empty(), "Eine Truhe offen: Xiulan bleibt")
	b2.chests[1]["open"] = true
	await b2._flush_events()
	check(b2._find("xiulan").is_empty() and b2.retreated.has("xiulan"), "Beide Truhen offen: Xiulan zieht ab")
	check(said.count("xiulan") >= 2, "Xiulan spricht zum Geld: %s" % [said])
	b2.turn = 4
	print("sumpf: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
