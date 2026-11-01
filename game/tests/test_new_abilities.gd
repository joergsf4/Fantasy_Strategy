extends SceneTree
## godot --headless --path game --script tests/test_new_abilities.gd
## Die 14 neuen Faehigkeiten (docs/faehigkeiten_plan.md) und die gemeinsame Abklingzeit.

var fails := 0
var b: Battle


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
	b.rng.seed = 11
	# --- Gemeinsame Abklingzeit
	clear()
	var rit := spawn("ritter", "p", Vector2i(5, 5))
	spawn("soldat_infanterie", "e", Vector2i(9, 9))
	await b._run_ability(rit, "schlachtruf", rit)
	check(rit["cd"]["schlachtruf"] == 4 and rit["cd"]["verspotten"] == 4, "Albrecht: beide Faehigkeiten teilen die Abklingzeit")
	clear()
	var maja := spawn("maja", "e", Vector2i(5, 5))
	await b._run_ability(maja, "einschuechtern", maja)
	check(int(maja["cd"].get("flucht", 0)) == 0, "Majas Flucht ist von der gemeinsamen Abklingzeit ausgenommen")

	# --- Wollmantel: halber Schaden
	clear()
	var wendy := spawn("wendy", "p", Vector2i(5, 5))
	var ally := spawn("soldat_infanterie", "p", Vector2i(6, 5))
	var foe := spawn("soldat_infanterie", "e", Vector2i(7, 5))
	var full: int = Combat.damage(foe, ally, 0, 0.0)
	await b._run_ability(wendy, "wollmantel", ally)
	check(Status.has(ally, "schild"), "Wollmantel: Status gesetzt")
	var half: int = Combat.damage(foe, ally, 0, 0.0)
	check(half == maxi(1, ceili(full * 0.5)), "Wollmantel: halber Schaden (%d -> %d)" % [full, half])

	# --- Baerengebruell: Gegner bekommt Angst und weicht aus
	clear()
	var mira := spawn("maedchen_baer", "p", Vector2i(5, 5))
	var e := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	await b._run_ability(mira, "baerengebruell", e)
	check(Status.has(e, "angst"), "Gebruell: Angst")
	var d0 := Grid.dist(e["pos"], mira["pos"])
	var hp0: int = mira["hp"]
	await b._enemy_move(e)
	check(Grid.dist(e["pos"], mira["pos"]) > d0, "Eingeschuechterter Gegner laeuft weg")
	check(mira["hp"] == hp0, "Eingeschuechterter Gegner greift nicht an")

	# --- Stabwirbel: alle Nachbarn
	clear()
	var lin := spawn("kungfu", "p", Vector2i(5, 5))
	var a1 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	var a2 := spawn("soldat_infanterie", "e", Vector2i(4, 4))
	var far := spawn("soldat_infanterie", "e", Vector2i(8, 8))
	await b._run_ability(lin, "stabwirbel", lin)
	check(a1["hp"] < a1["maxhp"] and a2["hp"] < a2["maxhp"] and far["hp"] == far["maxhp"], "Stabwirbel trifft die Nachbarn, nicht Ferne")
	check(not Status.has(lin, "tired"), "Stabwirbel ohne Erschoepfung")

	# --- Prost: heilt angrenzenden Verbuendeten
	clear()
	var bru := spawn("braumeisterin", "p", Vector2i(5, 5))
	var hurt := spawn("ritter", "p", Vector2i(6, 5))
	hurt["hp"] = 10
	spawn("soldat_infanterie", "e", Vector2i(9, 9))
	check(b._ab_targets(bru, "prost", bru["pos"]).has(hurt), "Prost: verwundeter Nachbar ist Ziel")
	await b._run_ability(bru, "prost", hurt)
	check(hurt["hp"] == 18, "Prost heilt 8")
	hurt["pos"] = Vector2i(8, 5)
	check(b._ab_targets(bru, "prost", bru["pos"]).is_empty(), "Prost: nur angrenzend")

	# --- Bearhug
	clear()
	var aug := spawn("museklaugust", "p", Vector2i(5, 5))
	var fo := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	var normal: int = Combat.damage(aug, fo, 0, 0.0)
	await b._run_ability(aug, "bearhug", fo)
	check(fo["hp"] < fo["maxhp"] - normal, "Bearhug schlaegt haerter als ein Angriff")

	# --- Kyujutsu: Reichweite 4, Schaden wie Nahkampf
	clear()
	var dek := spawn("samurai", "p", Vector2i(2, 5))
	var fo2 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	check(b._ab_targets(dek, "kyujutsu", dek["pos"]).has(fo2), "Kyujutsu: Ziel in 4 Feldern")
	var mel: int = Combat.damage(dek, fo2, 0, 0.0)
	await b._run_ability(dek, "kyujutsu", fo2)
	check(fo2["maxhp"] - fo2["hp"] == mel, "Kyujutsu: Schaden wie Nahkampf (%d)" % mel)
	fo2["pos"] = Vector2i(8, 5)
	check(not b._ab_targets(dek, "kyujutsu", dek["pos"]).has(fo2), "Kyujutsu: 6 Felder sind zu weit")

	# --- Brandbombe: Brennen tickt
	clear()
	var osk := spawn("oskar", "p", Vector2i(3, 5))
	var fo3 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	spawn("ritter", "p", Vector2i(0, 0))
	await b._run_ability(osk, "brandbombe", fo3)
	check(Status.has(fo3, "brennen"), "Brandbombe: Ziel brennt")
	var hp3: int = fo3["hp"]
	await b._begin_phase("e")
	check(fo3["hp"] == hp3 - Status.BURN_DAMAGE, "Brennen: %d Schaden pro Runde" % Status.BURN_DAMAGE)

	# --- Flucht (Maja): Rand, 20 % heilen, nur einmal
	clear()
	var mj := spawn("maja", "e", Vector2i(6, 6))
	spawn("ritter", "p", Vector2i(5, 6))
	mj["hp"] = 8
	await b._enemy_move(mj)
	var g: Grid = b.grid
	check(mj["pos"].x in [0, g.width - 1] or mj["pos"].y in [0, g.height - 1], "Maja steht nach der Flucht am Kartenrand")
	check(mj["hp"] == 8 + roundi(0.2 * mj["maxhp"]), "Maja erholt sich um 20 %")
	check(int(mj["cd"]["flucht"]) > 50, "Flucht nur einmal pro Kampf")

	# --- Tonikum: Verbuendete schneller, Gegner uebel
	clear()
	var hum := spawn("quacksalber", "p", Vector2i(4, 5))
	var fr := spawn("ritter", "p", Vector2i(6, 5))
	var gg := spawn("soldat_infanterie", "e", Vector2i(7, 5))
	check(not b._ab_tiles(hum, "tonikum", hum["pos"]).is_empty(), "Tonikum: Zielfelder vorhanden")
	await b._run_ability(hum, "tonikum", {"pos": Vector2i(6, 5), "tile": true})
	check(Status.has(fr, "tempo") and Combat.move_of(fr) == fr["move"] + 1, "Tonikum: Verbuendeter +1 Bewegung")
	check(Status.has(gg, "uebel") and Combat.move_of(gg) == gg["move"] - 2, "Tonikum: Gegner uebel, -2 Bewegung")

	# --- Hinterhalt: nur von hinten, normale Gegner sofort tot
	clear()
	var nin := spawn("ninjas", "p", Vector2i(4, 5))
	var sol := spawn("soldat_infanterie", "e", Vector2i(5, 5))
	spawn("ritter", "p", Vector2i(0, 0))
	sol["dir"] = Vector2i.LEFT           # blickt zum Ninja
	check(not b._ab_targets(nin, "hinterhalt", nin["pos"]).has(sol), "Hinterhalt: von vorne nicht moeglich")
	sol["dir"] = Vector2i.RIGHT          # blickt weg
	check(b._ab_targets(nin, "hinterhalt", nin["pos"]).has(sol), "Hinterhalt: von hinten moeglich")
	await b._run_ability(nin, "hinterhalt", sol)
	check(not b.units.has(sol), "Hinterhalt toetet normalen Gegner sofort")
	var boss := spawn("fuerst", "e", Vector2i(5, 5))
	boss["dir"] = Vector2i.RIGHT
	await b._run_ability(nin, "hinterhalt", boss)
	check(boss["hp"] > 0 and boss["hp"] < boss["maxhp"], "Hinterhalt gegen Boss: nur Schaden")

	# --- Bellen: mindestens einer bekommt Angst
	clear()
	var hund := spawn("hund", "p", Vector2i(5, 5))
	var bs: Array = []
	for pos in [Vector2i(6, 5), Vector2i(5, 7), Vector2i(3, 5), Vector2i(5, 3)]:
		bs.append(spawn("soldat_infanterie", "e", pos))
	var far2 := spawn("soldat_infanterie", "e", Vector2i(11, 11))
	await b._run_ability(hund, "bellen", hund)
	check(bs.any(func(x: Dictionary) -> bool: return Status.has(x, "angst")), "Bellen: mindestens ein Gegner hat Angst")
	check(not Status.has(far2, "angst"), "Bellen: Ferne bleiben unbeeindruckt")

	# --- Sternschnuppe: kartenweit
	clear()
	var lumi := spawn("magical_girl", "p", Vector2i(0, 0))
	var fo4 := spawn("soldat_infanterie", "e", Vector2i(11, 11))
	check(b._ab_targets(lumi, "sternschnuppe", lumi["pos"]).has(fo4), "Sternschnuppe: Ziel am anderen Kartenende")
	var base: int = Combat.damage(lumi, fo4, 0, 0.0)
	await b._run_ability(lumi, "sternschnuppe", fo4)
	check(fo4["maxhp"] - fo4["hp"] == base, "Sternschnuppe: normaler Angriffsschaden")

	# --- Wutanfall: doppelter Schaden, handelt selbst
	clear()
	var eli := spawn("elisabeth", "p", Vector2i(5, 5))
	var victim := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	var plain: int = Combat.damage(eli, victim, 0, 0.0)
	await b._run_ability(eli, "wutanfall", eli)
	check(Status.has(eli, "wut") and Combat.damage(eli, victim, 0, 0.0) >= plain * 2 - 1, "Wutanfall: doppelter Schaden")
	eli["done"] = false
	await b._rage_phase()
	check(eli["done"], "Wutanfall: Figur handelt selbst")

	# --- Bienenkorb: Objekt, schluepft Bienen, loest sich auf
	clear()
	var sta := spawn("bienenmaedchen", "p", Vector2i(5, 5))
	spawn("soldat_infanterie", "e", Vector2i(11, 11))
	check(not b._ab_tiles(sta, "bienenkorb", sta["pos"]).is_empty(), "Bienenkorb: Zielfelder vorhanden")
	await b._run_ability(sta, "bienenkorb", {"pos": Vector2i(6, 6), "tile": true})
	var hive := b.world.at(Vector2i(6, 6))
	check(not hive.is_empty() and hive["type"] == "hive_p", "Bienenkorb steht")
	for i in 3:
		await b._player_hive_phase()
	var bees := b.units.filter(func(x: Dictionary) -> bool: return x["id"] == "bienenkrieger" and x["team"] == "p")
	check(bees.size() == 1, "Bienenkorb: nach 3 Runden ein Bienenkrieger (%d)" % bees.size())
	for i in 4:
		await b._player_hive_phase()
	check(hive["state"] == "gone", "Bienenkorb loest sich nach 6 Runden auf")
