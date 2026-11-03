extends SceneTree
## godot --headless --path game --script tests/test_labor.gd
## Kapitel 13 "Das Labor im Wald": drei Kinder befreien (free_all), Energiemaschine schockt Helden daneben, Professor flieht, Bonus Maschine zerstoert.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch13")
	check(m["goals"][0]["type"] == "free_all", "Ziel: alle befreien")
	for id: String in Mission.dialogue_ids("ch13"):
		check(defs.has(id) or id == "waisenkinder", "Sprecher %s existiert" % id)
	for id in ["kugelblitz", "kugelblitz_lachend", "kugelblitz_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Portrait %s" % id)
	for id in ["cyborg_wart", "cyborg_wart_lachend", "cyborg_wart_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Portrait %s" % id)
	check(ResourceLoader.exists("res://assets/fx/fx_glaszylinder.png") and ResourceLoader.exists("res://assets/fx/fx_glaszylinder_kaputt.png") and ResourceLoader.exists("res://assets/tokens/cyborg_wart.png"), "Behaelter und Cyborg-Karten-Figur")
	check(ResourceLoader.exists("res://assets/tokens/kugelblitz.png") and ResourceLoader.exists("res://assets/fx/fx_maschine.png"), "Karten-Figur und Maschine")
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	await process_frame
	check(not b.goal_met(), "Anfangs sind die Kinder gefesselt")
	# Maschine schockt Helden direkt daneben
	var hero := b._find("hund")
	hero["pos"] = Vector2i(7, 5)      # neben der Maschine (8,5)
	var hp0: int = hero["hp"]
	b._actor = {}
	await b._machine_phase()
	check(hero["hp"] == hp0 - 5, "Zap: 5 Schaden neben der Maschine (%d -> %d)" % [hp0, hero["hp"]])
	hero["pos"] = Vector2i(2, 5)
	var hp1: int = hero["hp"]
	await b._machine_phase()
	check(hero["hp"] == hp1, "Weit weg: kein Schaden")
	# Kinder befreien
	for id in ["kind1", "kind2"]:
		b.world.by_id(id)["state"] = "free"
	check(not b.goal_met(), "Zwei von drei befreit: noch nicht geschafft")
	b.world.by_id("kind3")["state"] = "free"
	check(b.goal_met(), "Alle drei frei: Ziel erreicht")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true] and said.has("kugelblitz") and said.has("waisenkinder"), "Abschlussszenen: %s" % [said])
	check(b.retreated.has("kugelblitz"), "Professor zieht sich zurueck")
	check(b.results()["objectives"][1]["done"] == false, "Maschine noch heil: kein Bonus")
	b.world.by_id("maschine")["state"] = "broken"
	b._results.clear()
	check(b.results()["objectives"][1]["done"] == true, "Maschine zerstoert: Bonus")
	# Cyborg-Wart: faellt die Gesundheit der Frischlinge unter die Haelfte, birst der Behaelter und er erscheint
	var b3 := Battle.new()
	b3.setup(Mission.load_mission("ch13"), defs)
	b3.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b3)
	await process_frame
	check(b3._find("cyborg_wart").is_empty() and b3.world.by_id("zylinder")["state"] == "intact", "Anfangs ist der Behaelter heil, kein Cyborg")
	said.clear()
	var fr := b3._find("frischlinge")
	check(not fr.is_empty() and fr["maxhp"] == roundi(55.0 * float(Progression.enemy_scale("ch13")["hp"])), "Frischlinge stehen auf der Karte")
	fr["hp"] = int(fr["maxhp"] * 0.4)
	await b3._flush_events()
	check(b3.world.by_id("zylinder")["state"] == "broken", "Behaelter geborsten")
	var cw := b3._find("cyborg_wart")
	check(not cw.is_empty() and cw["team"] == "e", "Cyborg-Wart ist da: %s" % [said])
	check(said.has("cyborg_wart"), "Cyborg-Wart spricht")
	check((cw["abilities"] as Array).has("rakete") and (cw["abilities"] as Array).has("computer_analyse"), "Raketenwerfer und Computer-Analyse")
	# Computer-Analyse: Ziel nimmt 20 % mehr Schaden
	var tgt := b3._find("ritter")
	var base := Combat.damage(cw, tgt, 0, 0.0, 1.0)
	Status.add(tgt, "analysiert", 3)
	var more := Combat.damage(cw, tgt, 0, 0.0, 1.0)
	check(more == maxi(1, ceili(float(base) * 1.2)) and more > base, "Analysiert: %d -> %d (+20 %%)" % [base, more])
	cw["pos"] = Vector2i(tgt["pos"].x + 2, tgt["pos"].y)
	Status.remove(tgt, "analysiert")
	await b3._enemy_debuff(cw, tgt)
	check(Status.has(tgt, "analysiert") and int(cw["cd"].get("computer_analyse", 0)) > 0, "KI analysiert das Ziel und die Faehigkeit ist auf Abklingzeit")
	print("labor: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
