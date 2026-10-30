extends SceneTree
## godot --headless --path game --script tests/test_flee.gd
## Benannte Gegner ("flees") sterben nicht: Rueckzug mit Dialog, Beute, Merken in der Party, Wiederkehr in spaeteren Missionen.

var fails := 0
var b: Battle
var shown: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	var m := Mission.load_mission("ch2")
	m["players"] = []
	m["enemies"] = []
	m["triggers"] = []
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void: shown.append(lines)
	root.add_child(b)
	await process_frame
	await run_tests(defs)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func run_tests(defs: Dictionary) -> void:
	for id in ["wart", "oskar", "maja"]:
		check(defs[id].get("flees", false), "%s flieht statt zu sterben" % id)
	check(not defs["soldat_infanterie"].get("flees", false), "Soldaten sterben")
	b._spawn("ritter", "p", Vector2i(2, 6))
	var hero: Dictionary = b.units.back()
	b._spawn("wart", "e", Vector2i(2, 5), {"carry": {"gold": 40}})
	var wart: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(5, 5))
	var soldat: Dictionary = b.units.back()
	b._actor = hero
	# Wart faellt: flieht, Dialog, Beute, keine Leiche
	wart["hp"] = 0
	b.units.erase(wart)
	await b._down(wart)
	check(b.fled == ["wart"], "Wart ist als geflohen vermerkt")
	check(b._find("wart").is_empty(), "Wart ist nicht mehr auf dem Feld")
	check(shown.size() == 1 and (shown[0] as Array)[0]["left"] == hero["id"], "Fluchtdialog laeuft, $hero wird ersetzt")
	check(int(b.loot["gold"]) == 40, "Beute faellt beim Rueckzug")
	check(not (b.fallen as Array).has("wart"), "nicht als gefallener Held gezaehlt")
	# normaler Gegner stirbt ohne Flucht
	soldat["hp"] = 0
	b.units.erase(soldat)
	await b._down(soldat)
	check(b.fled == ["wart"], "Soldat flieht nicht")
	check(b.goal_met(), "Rout-Ziel zaehlt Geflohene als besiegt")
	check(b.results()["fled"] == ["wart"], "Ergebnis meldet Geflohene")
	# Party merkt es sich, auch im Speicherstand
	var party := Party.new_game()
	party.absorb(b.results())
	check(party.nemesis == ["wart"], "Party merkt sich Wart")
	check((party.loadout()["nemesis"] as Array) == ["wart"], "Loadout reicht es in den Kampf")
	var back := Party.from_dict(party.to_dict())
	check(back.nemesis == ["wart"], "Speicherstand behaelt Wart")
	# Wiederkehr: Bedingung "fled" im naechsten Kampf
	var b2 := Battle.new()
	var m3 := Mission.load_mission("ch3")
	b2.loadout = party.loadout()
	b2.setup(m3, JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json")))
	root.add_child(b2)
	await process_frame
	check(b2._cond_ok({"fled": ["wart"]}), "Wart ist im naechsten Kampf als entkommen bekannt")
	check(not b2._cond_ok({"fled": ["oskar"]}), "Oskar nicht")
	var b3 := Battle.new()
	b3.setup(Mission.load_mission("ch3"), JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json")))
	root.add_child(b3)
	await process_frame
	check(not b3._cond_ok({"fled": ["wart"]}), "ohne Vorgeschichte kehrt niemand zurueck")
	var back_trig := (m3["triggers"] as Array).filter(func(t: Dictionary) -> bool: return (t.get("if", {}) as Dictionary).has("fled"))
	check(back_trig.size() == 1, "Mission 3 hat die Wiederkehr von Wart")
	b2._run_triggers("turn", 3)
	await create_timer(0.5).timeout
	check(not b2._find("wart").is_empty(), "Wart taucht in Mission 3 wieder auf")
