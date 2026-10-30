extends SceneTree
## godot --headless --path game --script tests/test_villains.gd
## Wart (Rakete), Oskar (Befehl), Maja (Eisiger Blick): Wirkung, Einsatz durch die Gegner-KI, Missionsdaten.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	var m := Mission.load_mission("ch1")
	m["players"] = []
	m["enemies"] = []
	m["triggers"] = []
	b.setup(m, defs)
	root.add_child(b)
	await process_frame
	await run_tests(defs)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func scene(heroes: Array, foes: Array) -> Array:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE
	var out: Array = []
	for h: Array in heroes:
		b._spawn(h[0], "p", Vector2i(h[1][0], h[1][1]))
		out.append(b.units.back())
	for f: Array in foes:
		b._spawn(f[0], "e", Vector2i(f[1][0], f[1][1]))
		out.append(b.units.back())
	return out


func run_tests(defs: Dictionary) -> void:
	# Einheiten vorhanden, Boss-Marke (nicht verwandelbar), Bilder da
	for id in ["wart", "oskar", "maja"]:
		check(defs.has(id) and (defs[id]["tags"] as Array).has("boss"), "%s ist definiert und ein Boss" % id)
		check(ResourceLoader.exists("res://assets/tokens/%s.png" % id) and ResourceLoader.exists("res://assets/portraits/%s_wuetend.png" % id), "%s hat Karten-Figur und Portraets" % id)
	# Missionen verwenden nur bekannte Einheiten
	for cid in ["ch1", "ch2", "ch3"]:
		var mm := Mission.load_mission(cid)
		for e: Dictionary in (mm["players"] as Array) + (mm["enemies"] as Array):
			check(defs.has(e["id"]) and ResourceLoader.exists("res://assets/tokens/%s.png" % e["id"]), "%s: Einheit %s bekannt" % [cid, e["id"]])
	var ch2 := Mission.load_mission("ch2")
	var ch3 := Mission.load_mission("ch3")
	check((ch2["enemies"] as Array).any(func(e: Dictionary) -> bool: return e["id"] == "wart"), "Hohlweg: Wart ist Gegner")
	check((ch3["enemies"] as Array).any(func(e: Dictionary) -> bool: return e["id"] == "oskar") and (ch3["enemies"] as Array).any(func(e: Dictionary) -> bool: return e["id"] == "maja"), "Feuer-Dorf: Oskar und Maja sind Gegner")
	check(not (ch2["enemies"] as Array).any(func(e: Dictionary) -> bool: return e["id"] == "xiulan"), "Xiulan bleibt aufgehoben")

	# --- Rakete: Treffer plus halber Schaden auf Nachbarn, Reichweite 2-4
	var s := scene([["ritter", [7, 7]], ["kungfu", [8, 7]], ["samurai", [7, 2]]], [["wart", [4, 7]]])
	var wart: Dictionary = s[3]
	check(b._ab_targets(wart, "rakete", wart["pos"]).has(s[0]) and not b._ab_targets(wart, "rakete", wart["pos"]).has(s[2]), "Rakete: Ziel in Reichweite 3 ja, ferne Figur nein")
	var h0: int = s[0]["hp"]
	var h1: int = s[1]["hp"]
	await b._run_ability(wart, "rakete", s[0])
	var d0: int = h0 - s[0]["hp"]
	var d1: int = h1 - s[1]["hp"]
	check(d0 > 0 and d1 > 0 and d1 < d0, "Rakete: Ziel %d, Nachbar %d (weniger)" % [d0, d1])
	check(wart["cd"]["rakete"] == 3, "Rakete: Abklingzeit 3")

	# --- Oskar: Befehl nur bei mindestens 2 Verbuendeten im Umkreis 3
	s = scene([["ritter", [3, 7]]], [["oskar", [7, 3]], ["soldat_infanterie", [8, 3]]])
	var oskar: Dictionary = s[1]
	check(b._enemy_self_ability(oskar) == "", "Befehl: nur 1 Verbuendeter im Umkreis, nicht eingesetzt")
	b._spawn("soldat_beritten", "e", Vector2i(7, 4))
	check(b._enemy_self_ability(oskar) == "befehl", "Befehl: 2 Verbuendete im Umkreis, wird eingesetzt")
	var inf: Dictionary = s[2]
	var atk0: int = Combat.stat(inf, "atk")
	await b._run_ability(oskar, "befehl", oskar)
	check(Combat.stat(inf, "atk") == atk0 + 3 and Combat.stat(inf, "def") == inf["def"] + 2, "Befehl: Verbuendete +3 ATK +2 DEF")
	check(Combat.stat(oskar, "atk") == oskar["atk"] + 3, "Befehl wirkt auch auf Oskar selbst")
	check(Combat.stat(s[0], "atk") == s[0]["atk"], "Befehl: Helden unberuehrt")
	check(b._enemy_self_ability(oskar) == "", "Befehl: Abklingzeit laeuft, nicht gleich wieder")

	# --- Maja: Eisiger Blick auf Helden im Umkreis 2
	s = scene([["ritter", [5, 5]], ["samurai", [9, 9]]], [["maja", [5, 4]]])
	var maja: Dictionary = s[2]
	check(b._enemy_self_ability(maja) == "einschuechtern", "Maja: Held in Reichweite 1, Blick wird eingesetzt")
	var a0: int = Combat.stat(s[0], "atk")
	await b._run_ability(maja, "einschuechtern", maja)
	check(Combat.stat(s[0], "atk") == a0 - 3 and Combat.stat(s[0], "def") == s[0]["def"] - 1 and Status.has(s[0], "scared"), "Blick: Albrecht eingeschuechtert (-3 ATK, -1 DEF)")
	check(Combat.stat(s[1], "atk") == s[1]["atk"], "Blick: ferner Held unberuehrt")
	check(Status.NAMES["scared"] == "Eingeschüchtert", "Status hat einen Namen")
	await b._begin_phase("p")
	await b._begin_phase("p")
	check(not Status.has(s[0], "scared"), "Eingeschuechtert endet nach 2 Phasen")
	s = scene([["ritter", [5, 9]]], [["maja", [5, 4]]])
	check(b._enemy_self_ability(s[1]) == "", "Maja: Held 5 Felder weg, kein Blick")

	# --- Die KI nutzt die Faehigkeit im Zug (statt zu schlagen)
	s = scene([["ritter", [5, 5]], ["wendy", [0, 9]]], [["maja", [5, 3]]])
	await b._enemy_move(s[2])
	check(s[2]["cd"].get("einschuechtern", 0) > 0 and Status.has(s[0], "scared"), "Gegner-KI: Maja setzt den Eisigen Blick im Zug ein")
	# Wart schiesst im Zug mit der Rakete, wenn ein Ziel in Reichweite 2-4 steht
	s = scene([["ritter", [8, 5]], ["wendy", [0, 9]]], [["wart", [5, 5]]])
	var hp_before: int = s[0]["hp"]
	await b._enemy_move(s[2])
	check(s[2]["cd"].get("rakete", 0) > 0 and s[0]["hp"] < hp_before, "Gegner-KI: Wart nutzt die Rakete (Albrecht %d -> %d)" % [hp_before, s[0]["hp"]])
