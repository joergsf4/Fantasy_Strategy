extends SceneTree
## godot --headless --path game --script tests/test_secrets.gd
## Geheime Interaktionen: Brunhilde wirft ein Fass auf Lin -> Betrunkener Meister + Drunken Strike.

var fails := 0
var b: Battle
var scenes_shown: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	map["rows"] = []
	for y in 12:
		(map["rows"] as Array).append("GGGGGGGGGGGG")
	for k in ["objects", "chests", "triggers", "decor"]:
		if map.has(k):
			map[k] = []
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(map, defs)
	b.secret_runner = func(sec: Dictionary) -> void:
		scenes_shown.append(sec["id"])
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func clear() -> void:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE


func spawn(id: String, team: String, pos: Vector2i) -> Dictionary:
	b._spawn(id, team, pos)
	return b.units.back()


func run_tests() -> void:
	b.rng.seed = 5
	# Daten
	var sec := Secrets.find("braumeisterin", "fasswurf", "kungfu")
	check(not sec.is_empty() and sec["id"] == "betrunkener_meister", "Geheimnis in secrets.json gefunden")
	check(Secrets.find("braumeisterin", "fasswurf", "ritter").is_empty(), "Fasswurf auf Albrecht ist kein Geheimnis")
	check(ResourceLoader.exists("res://assets/portraits/%s.png" % sec["scene"]["left"]) and ResourceLoader.exists("res://assets/portraits/%s.png" % sec["scene"]["right"]), "Bilder der Szene existieren")
	check(ResourceLoader.exists("res://assets/secrets/%s.jpg" % sec["scene"]["background"]), "Hintergrund existiert")

	# Zielwahl: nur Lin ist als Verbuendeter zielbar
	clear()
	var bru := spawn("braumeisterin", "p", Vector2i(4, 5))
	var lin := spawn("kungfu", "p", Vector2i(6, 5))
	var alb := spawn("ritter", "p", Vector2i(5, 6))
	var foe := spawn("soldat_infanterie", "e", Vector2i(9, 9))
	var t := b._ab_targets(bru, "fasswurf", bru["pos"])
	check(t.has(lin) and not t.has(alb) and t.has(foe) == (Grid.dist(bru["pos"], foe["pos"]) <= 3), "Fasswurf: Lin ist Ziel, Albrecht nicht")
	var atk0: int = Combat.stat(lin, "atk")
	var hp0: int = lin["hp"]

	# Ausloesen
	await b._run_ability(bru, "fasswurf", lin)
	check(Status.has(lin, "betrunken"), "Lin hat Bierlaune")
	check(Combat.stat(lin, "atk") > atk0 and Combat.stat(lin, "atk") <= atk0 + maxi(1, roundi(atk0 * 0.1)), "Angriff steigt um 10 %% (%d -> %d)" % [atk0, Combat.stat(lin, "atk")])
	check((lin["abilities"] as Array).has("drunken_strike"), "Lin bekommt Drunken Strike")
	check(lin["hp"] == hp0, "Das Fass verletzt Lin nicht")
	check(scenes_shown == ["betrunkener_meister"] and b.secrets_seen.has("betrunkener_meister"), "Szene lief beim ersten Mal")
	check(int(bru["cd"]["fasswurf"]) == 3, "Abklingzeit gesetzt")
	check(not b._ab_targets(bru, "fasswurf", bru["pos"]).has(lin), "Zweites Mal: Lin ist kein Ziel mehr")

	# Drunken Strike: drei Treffer, ignoriert Verteidigung teilweise
	clear()
	var lin2 := spawn("kungfu", "p", Vector2i(5, 5))
	(lin2["abilities"] as Array).append("drunken_strike")
	var f2 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	f2["hp"] = 100
	f2["maxhp"] = 100
	var one: int = Combat.damage(lin2, f2, 0, 0.0, 0.9, 0.3)
	await b._run_ability(lin2, "drunken_strike", f2)
	check(100 - f2["hp"] == one * 3, "Drunken Strike: drei Hiebe zu je %d (verloren: %d)" % [one, 100 - f2["hp"]])
	check(int(lin2["cd"]["drunken_strike"]) == 3 and int(lin2["cd"].get("stabwirbel", 0)) == 3, "Gemeinsame Abklingzeit mit Stabwirbel")

	# zweiter Kampf: Szene nur beim ersten Mal (Party merkt sich es)
	scenes_shown.clear()
	clear()
	var bru3 := spawn("braumeisterin", "p", Vector2i(4, 5))
	var lin3 := spawn("kungfu", "p", Vector2i(6, 5))
	b.secrets_done.clear()
	await b._run_ability(bru3, "fasswurf", lin3)
	check(scenes_shown.is_empty() and Status.has(lin3, "betrunken"), "Spaeter: keine Szene mehr, Effekt bleibt")
	# Party-Speicher
	var p := Party.new_game()
	p.absorb({"inventory": {}, "materials": {}, "gold": 0, "equipment": [], "secrets_seen": ["betrunkener_meister"]})
	check(p.secrets_seen == ["betrunkener_meister"] and (p.loadout()["secrets_seen"] as Array).has("betrunkener_meister"), "Party merkt gesehene Szene")
	check(Party.from_dict(p.to_dict()).secrets_seen == ["betrunkener_meister"], "Speichern und Laden")
