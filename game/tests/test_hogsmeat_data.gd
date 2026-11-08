extends SceneTree

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch20")
	check(m["title"] == "Hogsmeat" and m["goals"][0]["type"] == "rout", "Mission und Kampfziel")
	var ids: Array = (m["enemies"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	check(ids.count("hogsmeat_krieger") == 3 and ids.count("hogsmeat_speerwerfer") == 2, "Drei Nahkaempfer, zwei Speerwerfer")
	check(ids.count("frischlinge") == 1 and not ids.has("cyborg_wart") and defs["frischlinge"]["flees"] and defs["cyborg_wart"]["flees"], "Frischlinge beginnen auf der Karte, Robowart nicht; beide duerfen fliehen")
	var trigger: Dictionary = m["triggers"][0]
	check(trigger["when"]["flee"] == "frischlinge" and trigger["do"][0]["spawn"][0]["id"] == "cyborg_wart", "Robowart folgt auf die Flucht der Frischlinge")
	check(int(defs["hogsmeat_speerwerfer"]["range_min"]) == 2 and int(defs["hogsmeat_speerwerfer"]["range"]) == 3, "Speerwerfer-Reichweite")
	check((defs["hogsmeat_krieger"]["passives"] as Array).has("schildwall"), "Nahkaempfer haben Schildwall")
	var grid := Grid.new(m["rows"])
	var occupied := {}
	for entry: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
		var pos := Vector2i(entry["pos"][0], entry["pos"][1])
		check(grid.inside(pos) and grid.cost(pos) > 0 and not occupied.has(pos) and defs.has(entry["id"]), "Gueltige einzigartige Startposition fuer %s" % entry["id"])
		occupied[pos] = true
	var reachable := grid.reachable(Vector2i(5, 8), 100)
	for entry: Dictionary in m["enemies"]:
		check(reachable.has(Vector2i(entry["pos"][0], entry["pos"][1])), "Gegner %s erreichbar" % entry["id"])
	var sim := SimSetup.build({"map": "ch20", "players": [], "enemies": [], "e_mods": {"hp": 2.0, "atk": 2.0}}, 42)
	check(sim.grid.rows == m["rows"], "Simulation verwendet die Hogsmeat-Karte")
	check(sim.units.size() == (m["players"] as Array).size() + (m["enemies"] as Array).size(), "Simulation verwendet die Missionsaufstellung")
	for entry: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
		var pos := Vector2i(entry["pos"][0], entry["pos"][1])
		var unit := sim.unit_at(pos)
		check(not unit.is_empty() and unit["id"] == entry["id"], "Simulation startet %s an der Kartenposition" % entry["id"])
	var sim_frischlinge := sim.unit_at(Vector2i(4, 3))
	sim._kill({}, sim_frischlinge, "")
	var sim_wart: Array = sim.units.filter(func(u: Dictionary) -> bool: return u["id"] == "cyborg_wart")
	check(sim_wart.size() == 1 and sim_wart[0]["maxhp"] == int(defs["cyborg_wart"]["hp"]) * 2 and sim.flee_spawns.is_empty(), "Simulation bringt Robowart einmal mit Gegnerfaktoren nach dem Rueckzug")
	var p := Party.new_game()
	p.squads["ch19"] = ["maedchen_baer", "hund", "samurai", "elisabeth", "robo", "wendy"]
	check(p.squad_for(m) == p.squads["ch19"], "Vorige Gruppe wird uebernommen")
	p.squads["ch20"] = ["maedchen_baer", "hund", "ritter", "elisabeth", "robo", "wendy"]
	check(p.squad_for(m) == p.squads["ch20"], "Eigene Auswahl hat Vorrang")
	check(Party.from_dict(p.to_dict()).squad_for(m) == p.squads["ch20"], "Auswahl bleibt im Spielstand")
	p.squads.erase("ch20")
	p.squads["ch19"] = ["hund", "maedchen_baer", "ritter", "elisabeth", "robo", "wendy"]
	var reordered := p.squad_for(m)
	check(reordered.size() == 6 and reordered[0] == "maedchen_baer" and reordered.count("maedchen_baer") == 1 and reordered.count("hund") == 1, "Pflichtfigur und uebernommene Gruppe ohne Duplikate")
	for path: String in ["res://assets/tokens/hogsmeat_krieger.png", "res://assets/tokens/hogsmeat_speerwerfer.png", "res://assets/fx/fx_hogsmeat_huette.png", "res://assets/fx/fx_hogsmeat_halle.png", "res://assets/fx/fx_hogsmeat_speer.png"]:
		check(ResourceLoader.exists(path) and load(path) != null, "Grafik importiert: " + path)
	print("hogsmeat_daten: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
