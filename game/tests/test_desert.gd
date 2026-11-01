extends SceneTree
## godot --headless --path game --script tests/test_desert.gd
## Mission 7 (Sandhafen): Wueste, Zwillinge fliehen nicht, neue Heiler, Gruppe mit tauschbarem Platz, Simulator.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	Sfx.muted = true
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch7")
	for e: Dictionary in (m["players"] as Array) + (m["enemies"] as Array):
		check(defs.has(e["id"]) and ResourceLoader.exists("res://assets/tokens/%s.png" % e["id"]), "Einheit %s bekannt" % e["id"])
	for id in ["fx_kaktus", "fx_palme", "fx_zelt"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % id), "Sprite %s da" % id)
	check(Grid.TERRAIN["D"]["cost"] == 2 and m["biome"] == "wueste", "Duene kostet 2, Karte ist Wueste")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	check(b.terrain.biome == "wueste", "Gelaende kennt das Biom")
	# Zwillinge sterben wirklich statt zu fliehen
	var oskar: Dictionary = b._find("oskar")
	check(oskar["maxhp"] == 34 and b._find("maja")["maxhp"] == 30, "Zwillinge haben ihre Grundwerte (34 und 30 Leben, Balancing in docs/balance.md)")
	check(Mission.load_mission("ch7")["triggers"].filter(func(t: Dictionary) -> bool: return t["when"].has("turn") and t["do"].any(func(s: Dictionary) -> bool: return s.has("spawn"))).is_empty(), "keine Verstaerkung in Mission 7")
	var hero: Dictionary = b._find("hund")
	b._actor = hero
	oskar["hp"] = 0
	b.units.erase(oskar)
	await b._down(oskar)
	check(not b.fled.has("oskar") and b._find("oskar").is_empty(), "Oskar flieht in Mission 7 nicht")
	# Heiler
	var lumi: Dictionary = b._find("magical_girl")
	var humbug: Dictionary = b._find("quacksalber")
	hero["hp"] = 5
	await b._run_ability(lumi, "sternensegen", hero)
	check(hero["hp"] == 12 and Status.has(hero, "buff") and Combat.stat(hero, "def") == defs["hund"]["def"] + 2, "Sternensegen heilt 7 und gibt +2 Verteidigung")
	hero["hp"] = 5
	Status.add(hero, "poison", 3)
	await b._run_ability(humbug, "wundersalbe", hero)
	check(hero["hp"] == 19 and not Status.has(hero, "poison") and Status.has(hero, "tired"), "Wundersalbe heilt 14, entgiftet, macht erschoepft")
	# Gruppe: Sprecher fest, einer tauschbar, Heiler waehlbar ab Kapitel 7
	var fixed := Mission.dialogue_ids("ch7")
	check(fixed.has("magical_girl") and fixed.has("quacksalber") and not fixed.has("ritter"), "Heiler sprechen, Albrecht ist tauschbar: %s" % [fixed])
	check(Party.roster(defs, 6).find("magical_girl") < 0 and Party.roster(defs, 7).has("magical_girl"), "neue Heiler ab Kapitel 7 waehlbar")
	# Simulator
	var sb := SimSetup.build({"map": "ch7", "players": [], "enemies": []}, 3)
	check(sb.units.size() == 6 + 6, "Simulator stellt Gruppe und Gegner auf")
	var w := sb.play(30)
	check(w in ["p", "e", "timeout"], "Simulationslauf laeuft durch (%s)" % w)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
