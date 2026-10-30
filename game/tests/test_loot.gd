extends SceneTree
## godot --headless --path game --script tests/test_loot.gd
## Truhen, Doerfer, Beute von Gegnern, Ziele, Party-Zustand und Speichern.

var fails := 0
var b: Battle
var map: Dictionary
var defs: Dictionary


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	map = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	# Eigene kleine Beute-Karte
	map["players"] = []
	map["enemies"] = []
	map["chests"] = [{"pos": [4, 7], "reward": {"items": {"heiltrank": 1}, "materials": {"kraut": 2}, "gold": 30}}]
	map["villages"] = [{"pos": [0, 3], "reward": {"materials": {"hopfen": 1}, "gold": 40}}]
	map["rewards"] = {"gold": 100}
	map["objectives"] = [
		{"id": "alle_leben", "text": "Kein Held faellt", "reward": {"gold": 60}},
		{"id": "schnell", "text": "In 3 Runden", "turns": 3, "reward": {"items": {"aether": 1}}}]
	b = Battle.new()
	b.setup(map, defs)
	b.loadout = {"inventory": {"heiltrank": 1}, "equipment": {}}
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func run_tests() -> void:
	# Truhe
	b._spawn("ritter", "p", Vector2i(4, 7))
	var hero: Dictionary = b.units.back()
	var chest := b._chest_at(Vector2i(4, 7))
	check(not chest.is_empty() and not chest["open"], "Truhe liegt auf (4,7), geschlossen")
	await b._collect(hero, chest, "chest")
	check(chest["open"], "Truhe ist offen")
	check(b.inventory["heiltrank"] == 2, "Truhe: Heiltrank im Rucksack (1+1)")
	check(b.loot["materials"].get("kraut", 0) == 2 and b.loot["gold"] == 30, "Truhe: 2 Kraut, 30 Gold in der Beute")
	check(hero["done"], "Aktion verbraucht: Figur ist fertig")
	# Dorf
	b._spawn("kungfu", "p", Vector2i(0, 3))
	var runner: Dictionary = b.units.back()
	var vil := b._village_at(Vector2i(0, 3))
	await b._collect(runner, vil, "village")
	check(vil["visited"] and b.loot["materials"].get("hopfen", 0) == 1 and b.loot["gold"] == 70, "Dorf: Hopfen und Gold, nur einmal")
	# Menue bietet bereits geoeffnete Truhe nicht mehr an
	check(b._chest_at(Vector2i(4, 7))["open"], "Truhe bleibt offen")
	# Beute-Traeger
	b._spawn("soldat_infanterie", "e", Vector2i(5, 7), {"carry": {"items": {"gegengift": 1}, "gold": 5}})
	var carrier: Dictionary = b.units.back()
	check(carrier.has("carry") and not (carrier["carry"] as Dictionary).is_empty(), "Gegner traegt Beute")
	carrier["hp"] = 1
	await b._strike(hero, carrier)
	check(not b.units.has(carrier), "Traeger besiegt")
	check(b.inventory.get("gegengift", 0) == 1 and b.loot["gold"] == 75, "Beute vom Traeger: Gegengift im Rucksack, +5 Gold")
	check((carrier["carry"] as Dictionary).is_empty(), "Beute nur einmal")
	# Ein Gegner ohne Beute gibt nichts
	b._spawn("soldat_infanterie", "e", Vector2i(6, 7))
	var plain: Dictionary = b.units.back()
	plain["hp"] = 1
	var gold_before: int = b.loot["gold"]
	await b._strike(hero, plain)
	check(b.loot["gold"] == gold_before, "Gegner ohne Beute: nichts")
	# Gefallene Helden werden vermerkt
	var res := b.results()
	check(res["objectives"][0]["done"], "Ziel 'kein Held faellt' erfuellt")
	check(res["objectives"][1]["done"], "Ziel 'in 3 Runden' erfuellt (Runde 1)")
	check(res["gold"] == 75 + 100 + 60, "Gold: Beute 75 + Kapitel 100 + Ziel 60 = %d" % res["gold"])
	check(res["inventory"].get("aether", 0) == 1, "Aether aus Ziel im Rucksack")
	check(b.results() == res and b.inventory.get("aether", 0) == 1, "results() zweimal aufrufen schreibt nicht doppelt gut")
	b._on_death({"team": "p", "id": "wendy"})
	check(b.fallen == ["wendy"], "Gefallener Held vermerkt")

	# Party: absorb, Speichern, Laden
	var p := Party.new_game()
	check(p.inventory.get("heiltrank", 0) == 2 and p.equipment.has("ritter"), "Neues Spiel: Startausstattung")
	p.absorb(res)
	check(p.gold == res["gold"] and p.materials.get("kraut", 0) == 2 and p.inventory["aether"] == 1 and p.chapter == 2, "Party uebernimmt Beute und Rucksack")
	var path := "user://test_party.json"
	p.save(path)
	var q := Party.load_from(path)
	check(q != null and q.gold == p.gold and q.inventory == p.inventory and q.materials == p.materials and q.equipment == p.equipment and q.chapter == 2, "Speichern und Laden ergibt dasselbe")
	check(Party.load_from("user://gibt_es_nicht.json") == null, "Fehlende Datei: null")
	check(not q.spend(99999) and q.spend(10) and q.gold == p.gold - 10, "Bezahlen: nur mit genug Gold")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
