extends SceneTree
## godot --headless --path game --script tests/test_rueckblende.gd
## Rueckblende nach Mission 3 (Takeda und die Kage-Schwestern, Biom fernost): erst Takeda gegen die Schwestern, beim Wendepunkt
## kommt die Stadtwache, die Schwestern wechseln die Seite, Elisabeth erscheint mit der Breitseite, neues Ziel: Takeda an Bord.
## Keine Belohnung, kein eigenes Kapitel (die Kapitelzaehlung bleibt unveraendert).

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var chapters_line := main_src.substr(main_src.find("const CHAPTERS"), 400).get_slice("\n", 0)
	check(chapters_line.contains('"ch26"') and not chapters_line.contains("rb_"), "Rueckblende steht nicht in der Kapitelliste")
	check(Mission.load_mission("ch3").get("flashback", "") == "rb_takeda", "Mission 3 spielt danach die Rueckblende")
	var m := Mission.load_mission("rb_takeda")
	check(m["no_rewards"] and m["fixed_squad"] and m["biome"] == "fernost", "ohne Belohnung, feste Gruppe, Biom fernost")
	check(m["goals"][0]["type"] == "defeat", "Anfangsziel: die Schwestern stellen")
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_rb_takeda.json"))
	var lines: Array = story["intro"] + story["outro"] + story["after"]
	for t: Dictionary in m["triggers"]:
		for step: Dictionary in t["do"]:
			lines += step.get("dialogue", [])
	for l: Dictionary in lines:
		var sp := str(l["speaker"])
		if sp != "$hero":
			check(ResourceLoader.exists("res://assets/portraits/%s.png" % sp), "Gespraechsbild fuer " + sp)
	for f in ["fx_haus_fernost1", "fx_haus_fernost2", "fx_dorf_fernost", "fx_pagode", "fx_torii", "fx_laterne", "fx_kirschbaum1", "fx_kirschbaum2"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % f), "Sprite " + f)
	check(ResourceLoader.exists("res://assets/tokens/stadtwache.png"), "Karten-Figur der Stadtwache")

	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(dl: Array) -> void:
		for l: Dictionary in dl:
			said.append(str(l["speaker"]))
	root.add_child(b)
	await process_frame
	var kage: Dictionary = b._find("kage_gegner")
	check(not b._find("samurai").is_empty() and kage["team"] == "e", "Takeda gegen die Schwestern")
	check(b._find("ninjas").is_empty() and b._find("elisabeth").is_empty(), "Schwestern und Elisabeth noch nicht auf unserer Seite")
	kage["hp"] = int(kage["maxhp"] * 0.5)
	await b._flush_events()
	var ninjas: Dictionary = b._find("ninjas")
	var lisa: Dictionary = b._find("elisabeth")
	check(not ninjas.is_empty() and ninjas["team"] == "p", "Schwestern wechseln die Seite")
	check(b._find("kage_gegner").is_empty(), "die gegnerischen Schwestern sind weg")
	check(not lisa.is_empty() and lisa["team"] == "p" and (lisa["abilities"] as Array).has("breitseite"), "Elisabeth mit Breitseite")
	check(b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "stadtwache").size() == 9, "neun Stadtwachen")
	check(b.goal["type"] == "reach" and b.goal["unit"] == "samurai", "neues Ziel: Takeda an Bord")
	check(said.has("stadtwache") and said.has("elisabeth"), "Wendepunkt mit Gespraech")
	check(not b.goal_met(), "Ziel nach dem Wendepunkt noch nicht erreicht")
	check(b.goal_tiles().size() == 3, "der ganze Steg ist Ziel")
	var tile: Vector2i = b.goal_tiles()[0]
	lisa["pos"] = tile
	check(not b.goal_met(), "Elisabeth auf dem Zielfeld zaehlt nicht")
	lisa["pos"] = Vector2i(12, 5)
	b._find("samurai")["pos"] = tile
	check(b.goal_met(), "Takeda auf dem Zielfeld: geschafft")
	var count := said.size()
	await b._run_triggers("turn", 3)
	check(said.size() == count and b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "stadtwache").size() == 9, "Wendepunkt nur einmal")
	print("rueckblende: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
