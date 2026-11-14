extends SceneTree
## godot --headless --path game --script tests/test_ch24.gd
## Mission 24 "Das leere Labor": Naehert sich die Gruppe dem mittleren Behaelter, platzen drei Behaelter und drei Robo-Frischlinge
## (Feuer, Blitz, Eis) greifen an. Sind sie besiegt, kommt Robo-Wart (flieht nicht). Gewonnen erst, wenn Robo-Wart besiegt ist.
## Dazu die drei Elementarkanonen: Feuer setzt Brand, Blitz springt auf Nachbarn ueber, Eis unterkuehlt (Bewegung -2, Verteidigung -1).

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _enemies(b: Battle) -> Array:
	return b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e")


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	check(FileAccess.get_file_as_string("res://scripts/main.gd").contains('"ch23", "ch24"'), "Mission 24 steht in der Kapitelliste")
	for v in ["", "_lachend", "_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/frischlinge_robo%s.png" % v), "Gespraechsbild Robo-Frischlinge " + v)
	check(FileAccess.get_file_as_string("res://data/missions/ch24.json").contains('"speaker": "frischlinge_robo"'), "Mission 24 nutzt das Robo-Gespraechsbild")
	var m := Mission.load_mission("ch24")
	check(m["goals"][0]["type"] == "defeat" and m["goals"][0]["unit"] == "cyborg_wart" and (m["no_flee"] as Array).has("cyborg_wart"), "Ziel: Robo-Wart besiegen, er flieht nicht")
	for f in ["frischling_feuer", "frischling_blitz", "frischling_eis"]:
		check(defs.has(f) and not defs[f].has("portrait"), "Einheit %s (eigenes Bild)" % f)
		check(ResourceLoader.exists("res://assets/tokens/%s.png" % f), "Sprite " + f)
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	await process_frame
	check(_enemies(b).is_empty(), "Zu Beginn ist das Labor leer")
	check(not b.goal_met(), "Ziel nicht erfuellt, solange Robo-Wart nie da war")
	await b._flush_events()
	check(_enemies(b).is_empty(), "Behaelter platzen nicht, solange niemand nah ist")
	# Ein Held naehert sich dem mittleren Behaelter: drei Robo-Frischlinge
	var hero: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")[0]
	hero["pos"] = Vector2i(6, 7)
	await b._flush_events()
	var ids := _enemies(b).map(func(u: Dictionary) -> String: return u["id"])
	ids.sort()
	check(ids == ["frischling_blitz", "frischling_eis", "frischling_feuer"], "drei Robo-Frischlinge, jeder eine eigene Figur: %s" % [ids])
	check(b.world.by_id("geraet_z2")["state"] == "broken", "Behaelter sind geplatzt")
	var sc := Progression.enemy_scale("ch24")      # Robo-Frischlinge in dieser Mission: +15 % Leben, +10 % Schaden
	var fe := b._find("frischling_feuer")
	var want_hp := roundi(float(roundi(float(defs["frischling_feuer"]["hp"]) * 1.15)) * float(sc["hp"]) * Settings.difficulty_mult())
	var want_atk := roundi(float(roundi(float(defs["frischling_feuer"]["atk"]) * 1.1)) * float(sc["atk"]) * Settings.difficulty_mult())
	check(int(fe["maxhp"]) == want_hp and int(fe["atk"]) == want_atk, "Robo-Frischling staerker: Leben %d (erwartet %d), Angriff %d (erwartet %d)" % [fe["maxhp"], want_hp, fe["atk"], want_atk])
	check(b._find("cyborg_wart").is_empty() and not b.goal_met(), "Robo-Wart noch nicht da, Mission nicht gewonnen")
	# Die drei Kanonen auf Helden
	var p: Array = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")
	var t1: Dictionary = p[0]
	var t2: Dictionary = p[1]
	t2["pos"] = t1["pos"] + Vector2i(1, 0)
	for x: Dictionary in [t1, t2]:
		x["hp"] = 200
		x["maxhp"] = 200
	await b._run_ability(b._find("frischling_feuer"), "flammenkanone", t1)
	check(Status.has(t1, "brennen") and t1["hp"] < 200, "Feuer: Schaden und Brand")
	var before := int(t2["hp"])
	await b._run_ability(b._find("frischling_blitz"), "blitzkanone", t1)
	check(int(t2["hp"]) < before, "Blitz springt auf den Nachbarn ueber")
	var move_before := Combat.move_of(t1)
	await b._run_ability(b._find("frischling_eis"), "frostkanone", t1)
	check(Status.has(t1, "unterkuehlt") and Combat.move_of(t1) < move_before, "Eis: unterkuehlt, langsamer (%d -> %d)" % [move_before, Combat.move_of(t1)])
	check(Status.NAMES.has("unterkuehlt"), "Statusname Unterkuehlt")
	# Schweinchen besiegt: Robo-Wart kommt
	for e in _enemies(b):
		b.units.erase(e)
	await b._flush_events()
	var wart := b._find("cyborg_wart")
	check(not wart.is_empty(), "Robo-Wart kommt, wenn die Schweinchen besiegt sind")
	check(not b.goal_met(), "Mission erst gewonnen, wenn Robo-Wart besiegt ist")
	await b._flush_events()
	check(b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "cyborg_wart").size() == 1, "Robo-Wart kommt nur einmal")
	b.units.erase(wart)
	check(b.goal_met(), "Robo-Wart besiegt: Mission gewonnen")
	# Abgang: Wart rappelt sich dort auf, wo er fiel, hat genug vom Verlieren und zieht mit seinen Frischlingen ab
	wart["pos"] = Vector2i(8, 3)
	var said: Array = []
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["text"]))
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true], "Mission gewonnen")
	check(said.any(func(t: String) -> bool: return t.contains("genug vom Verlieren")), "Wart hat genug vom Verlieren")
	for id in ["cyborg_wart", "frischling_feuer", "frischling_blitz", "frischling_eis"]:
		check(b.retreated.has(id) and b._find(id).is_empty(), "%s zieht ab" % id)
	check(b._spawn_base({"near": "cyborg_wart"}) == Vector2i(8, 3) or b.all_units.filter(func(u: Dictionary) -> bool: return u["id"] == "cyborg_wart").size() >= 2, "Abgang dort, wo Wart fiel")
	print("ch24: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
