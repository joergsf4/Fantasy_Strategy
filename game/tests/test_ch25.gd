extends SceneTree
## godot --headless --path game --script tests/test_ch25.gd
## Mission 25 (Finale, Biom Thronsaal): Der Professor sitzt unangreifbar auf dem Thron, der Sack und Xiùlán sitzen in Kaefigen.
## Stachelia (Pflicht) fuellt den Honig in die Maschine: der Professor flieht, der Sack besteigt den Thron, die Wachen greifen an.
## Der Sack wirft Messer auf Helden und Traenke auf Verbuendete. Xiùlán ist nach zwei Runden frei und kaempft als Gast mit.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _enemies(b: Battle) -> Array:
	return b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e")


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	check(FileAccess.get_file_as_string("res://scripts/main.gd").contains('"ch24", "ch25"'), "Mission 25 steht in der Kapitelliste")
	for f in ["fx_thron", "fx_kaefig", "fx_honigmaschine", "fx_honigmaschine_voll"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % f), "Bild " + f)
	for v in ["", "_lachend", "_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/sack_boss%s.png" % v), "Portrait sack_boss" + v)
	check(ResourceLoader.exists("res://assets/tokens/sack_boss.png"), "Spielfigur des Sacks")
	check(Mission.dialogue_ids("ch25").has("bienenmaedchen"), "Stachelia ist Pflicht")
	var m := Mission.load_mission("ch25")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["text"]))
	root.add_child(b)
	await process_frame
	var prof := b._find("kugelblitz")
	check(not prof.is_empty() and prof["idle"] and not b._hittable(prof), "Professor auf dem Thron: untaetig, unangreifbar")
	check(not b.goal_met(), "Ziel anfangs nicht erfuellt")
	var sack_cage := b.world.by_id("kaefig_sack")
	check(not b._hostage_option(sack_cage)["enabled"], "Kaefig des Sacks ist verschlossen")
	check(b._find("maja")["guard"] and b._find("oskar")["guard"], "Maja und Oskar bewachen den Thron")
	# Xiùlán befreien: zwei Runden
	var hero: Dictionary = b._find("ritter") if not b._find("ritter").is_empty() else b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")[0]
	var xc := b.world.by_id("kaefig_xiulan")
	hero["pos"] = xc["pos"] + Vector2i(0, 1)
	for e in _enemies(b):      # Wachen fern halten
		if Grid.dist(e["pos"], xc["pos"]) <= 1:
			e["pos"] = Vector2i(0, 9)
	check(b._hostage_option(xc)["text"].contains("1/2"), "Xiùlán: Fesseln loesen in zwei Schritten")
	await b._free_hostage(hero, xc)
	b.turn += 1
	hero["done"] = false
	b.state = Battle.State.IDLE
	await b._free_hostage(hero, xc)
	await b._flush_events()
	var xg := b._find("xiulan_gast")
	check(not xg.is_empty() and xg["team"] == "p" and xg["hp"] < xg["maxhp"], "Xiùlán kaempft als Gast mit (halbes Leben)")
	# Honig einfuellen: nur Stachelia neben der Maschine
	var hm := b.world.by_id("honigmaschine")
	var bee := b._find("bienenmaedchen")
	check(not bee.is_empty(), "Stachelia ist dabei")
	bee["pos"] = hm["pos"] + Vector2i(-1, 0)
	bee["done"] = false
	b.state = Battle.State.IDLE
	var said_before := said.size()
	await b._fill_honey(bee, hm)
	await b._flush_events()
	check(hm["state"] == "filled", "Honig ist in der Maschine")
	check(b._find("kugelblitz").is_empty() and b.retreated.has("kugelblitz"), "Der Professor flieht")
	check(sack_cage["state"] == "broken", "Kaefig des Sacks bricht auf")
	var sack := b._find("sack_boss")
	check(not sack.is_empty() and sack["pos"] == prof["pos"], "Der Sack sitzt auf dem Thron")
	check(said.size() > said_before and said.any(func(t: String) -> bool: return t.contains("Sohn")), "Enthuellung im Dialog")
	check(not b._find("maja")["guard"] and not b._find("oskar")["guard"], "Die Wachen greifen an")
	# Wuerfe des Sacks
	var t1: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")[0]
	t1["hp"] = 200
	t1["maxhp"] = 200
	await b._run_ability(sack, "wurfmesser", t1)
	check(t1["hp"] < 200, "Spitze Sachen: Schaden am Helden")
	var maja := b._find("maja")
	maja["hp"] = 5
	await b._run_ability(sack, "trankwurf", maja)
	check(maja["hp"] > 5, "Trank aus dem Beutel heilt Maja")
	check(b._ab_targets(sack, "trankwurf", sack["pos"]).has(maja), "KI findet verletzte Verbuendete als Trankziel")
	check(m["flee_below"]["maja"] == 0.3 and m["flee_below"]["oskar"] == 0.3, "Maja und Oskar fliehen schon bei 30 %")
	var osk := b._find("oskar")
	osk["hp"] = int(osk["maxhp"] * 0.35)
	await b._deal(osk, int(osk["maxhp"] * 0.1), "")
	check(b._find("oskar").is_empty() and b.fled.has("oskar") and osk["hp"] > 0, "Oskar flieht bei 30 % Leben")
	var maj := b._find("maja")
	var hero2: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")[0]
	hero2["hp"] = 200
	hero2["maxhp"] = 200
	hero2["pos"] = maj["pos"] + Vector2i(0, 1)
	maj["hp"] = int(maj["maxhp"] * 0.32)
	var hp_before := int(hero2["hp"])
	await b._resolve(hero2, maj)
	check(b._find("maja").is_empty() and int(hero2["hp"]) == hp_before, "Maja flieht nach dem Treffer und schlaegt nicht mehr zurueck")
	var sol := b._find("soldat_infanterie")
	sol["hp"] = int(sol["maxhp"] * 0.35)
	await b._deal(sol, int(sol["maxhp"] * 0.1), "")
	check(b.units.has(sol), "Soldaten fliehen nicht frueh")
	check((m["triggers"] as Array).any(func(t: Dictionary) -> bool: return (t["do"] as Array).any(func(st: Dictionary) -> bool: return st.has("beam"))), "Strahl von der Honigmaschine zum Kaefig")
	check(not b.goal_met(), "Noch nicht gewonnen")
	# Alle Gegner besiegt: gewonnen
	for e in _enemies(b):
		b.units.erase(e)
	check(b.goal_met(), "Alle Gegner besiegt: Mission gewonnen")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true], "Sieg")
	check(said.any(func(t: String) -> bool: return t.contains("Geld")), "Xiùlán im Abschluss")
	await _soldiers_cleared(defs)
	check(await _stachelia_falls(defs, false), "Stachelia faellt vor dem Honig: Mission verloren")
	check(not await _stachelia_falls(defs, true), "Stachelia faellt nach dem Honig: Mission laeuft weiter")
	print("ch25: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)


## Alle normalen Soldaten besiegt (vor dem Honig): von Sueden kommen zwei Buettel und ein Bogenschuetze, der Sack erinnert an den Honig. Immer wieder, bis der Honig drin ist.
func _soldiers_cleared(defs: Dictionary) -> void:
	var b := Battle.new()
	b.setup(Mission.load_mission("ch25"), defs)
	var heard: Array = []
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			heard.append(str(l["text"]))
	root.add_child(b)
	await process_frame
	var soldiers := ["soldat_infanterie", "soldat_bogenschuetze", "soldat_beritten"]
	for e in b.units.duplicate():
		if soldiers.has(e["id"]):
			b.units.erase(e)
	await b._flush_events()
	var fresh: Array = b.units.filter(func(u: Dictionary) -> bool: return soldiers.has(u["id"]))
	var ids: Array = fresh.map(func(u: Dictionary) -> String: return u["id"])
	ids.sort()
	check(ids == ["soldat_bogenschuetze", "soldat_infanterie", "soldat_infanterie"], "Nachschub: zwei Buettel und ein Bogenschuetze: %s" % [ids])
	check(fresh.all(func(u: Dictionary) -> bool: return int(u["pos"].y) >= 9), "Nachschub kommt von Sueden")
	check(heard.any(func(t: String) -> bool: return t.contains("Honig") and t.contains("Ostwand")), "Der Sack erinnert an die Aufgabe: %s" % [heard])
	var n := fresh.size()
	await b._flush_events()
	check(b.units.filter(func(u: Dictionary) -> bool: return soldiers.has(u["id"])).size() == n, "solange Soldaten leben, kein weiterer Nachschub")
	for e in b.units.duplicate():      # zweite Welle besiegt: wieder Nachschub und wieder der Hinweis
		if soldiers.has(e["id"]):
			b.units.erase(e)
	var hints := heard.size()
	await b._flush_events()
	check(b.units.filter(func(u: Dictionary) -> bool: return soldiers.has(u["id"])).size() == 3 and heard.size() > hints, "Nachschub und Hinweis kommen immer wieder")
	b.world.by_id("honigmaschine")["state"] = "filled"      # nach dem Honig: kein Nachschub mehr
	for e in b.units.duplicate():
		if soldiers.has(e["id"]):
			b.units.erase(e)
	await b._flush_events()
	check(b.units.filter(func(u: Dictionary) -> bool: return soldiers.has(u["id"])).is_empty(), "nach dem Honig kein Nachschub mehr")
	b.queue_free()


## Stachelia faellt (vor oder nach dem Honig). Rueckgabe: true, wenn die Mission damit verloren ist.
func _stachelia_falls(defs: Dictionary, honey: bool) -> bool:
	var b := Battle.new()
	b.setup(Mission.load_mission("ch25"), defs)
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	await process_frame
	if honey:
		b.world.by_id("honigmaschine")["state"] = "filled"
	var st := b._find("bienenmaedchen")
	b.units.erase(st)
	b.fallen.append("bienenmaedchen")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	var lost := b.state == Battle.State.OVER and got == [false]
	b.queue_free()
	await process_frame
	return lost
