extends SceneTree
## godot --headless --path game --script tests/test_capture.gd
## Kapitel 8: Robinas Panzer ist unantastbar, wird nach drei Runden in Folge neben ihm uebernommen und feuert als Gegner die Breitseite.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch8")
	check(m["goals"][0]["type"] == "capture" and m["title"] != "", "Kapitel 8 laedt mit Uebernahme-Ziel")
	var fixed := Mission.dialogue_ids("ch8")
	check(fixed.has("robo") and fixed.has("panzer") and not fixed.has("elisabeth") and not fixed.has("ritter"), "Robo (Schwester Robina) fest, Rest per Stimmen: %s" % [fixed])
	check(not fixed.has("wendy") and not fixed.has("quacksalber"), "Wendy und Dr. Humbug sind nicht festgelegt (Gruppenwahl)")
	b = Battle.new()
	b.setup(m, defs)
	root.add_child(b)
	await process_frame
	check(Mission.goal_text(b.goal, 6, 1, b._capture_info()).begins_with("Ziel: Haltet die Oase"), "Zieltext vor dem Panzer")
	b._spawn("panzer", "e", Vector2i(6, 7))
	var tank: Dictionary = b.units.back()
	var heroes := b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")
	var hero: Dictionary = heroes[0]
	# unantastbar
	hero["pos"] = Vector2i(6, 8)
	check(not b._attack_targets(hero, hero["pos"]).has(tank), "Angriffe zielen nicht auf den Panzer")
	check(b._ab_targets(hero, "roter_laser", hero["pos"]).filter(func(o: Dictionary) -> bool: return o == tank).is_empty(), "Fähigkeiten zielen nicht auf den Panzer")
	var spin: Array[Dictionary] = b._effect_targets(hero, b.abilities["todeswirbel"], hero, "area_enemies")
	check(not spin.has(tank), "Flaechenfaehigkeiten treffen den Panzer nicht")
	var gt := Mission.goal_text(b.goal, 6, 5, b._capture_info())
	check(gt.contains("(0/3") and gt.contains("Umprogrammieren") and gt.contains("einmal pro Runde"), "Zieltext erklaert die Aktion: %s" % gt)
	check(String(m["briefing"]).contains("Umprogrammieren"), "Briefing erklaert die Aktion")
	# Uebernahme ist eine Aktion: nur Robo, nur daneben, einmal pro Runde; Fortschritt bleibt, auch wenn der Panzer wegfaehrt
	await b._capture_phase()
	check(b.capture_progress == 0, "Danebenstehen allein zaehlt nicht mehr")
	var robo: Dictionary = b._find("robo")
	if robo.is_empty():
		b._spawn("robo", "p", Vector2i(1, 1))
		robo = b.units.back()
	robo["pos"] = Vector2i(5, 7)
	check(b._reprogram_target(hero).is_empty() or hero == robo, "Andere Helden koennen nicht umprogrammieren")
	robo["pos"] = Vector2i(2, 2)
	check(b._reprogram_target(robo).is_empty(), "Robo nicht daneben: keine Aktion")
	robo["pos"] = Vector2i(5, 7)
	check(b._reprogram_target(robo) == tank, "Robo daneben: Aktion moeglich")
	await b._reprogram(robo, tank)
	check(b.capture_progress == 1 and tank["team"] == "e" and b.capture_turn == b.turn, "Einsatz 1 von 3")
	tank["pos"] = Vector2i(9, 2)        # Panzer faehrt weg: Fortschritt bleibt
	b.turn += 1
	robo["pos"] = Vector2i(8, 2)
	robo["done"] = false
	await b._reprogram(robo, tank)
	check(b.capture_progress == 2, "Einsatz 2 von 3, Fortschritt blieb erhalten")
	b.turn += 1
	robo["done"] = false
	await b._reprogram(robo, tank)
	check(tank["team"] == "p" and b.goal_met(), "Nach drei Einsaetzen gehoert der Panzer uns, Ziel erreicht")
	check(str(b.map_data.get("lose_if_fallen", "")) == "robo" and String(m["briefing"]).contains("nicht fallen"), "Faellt Robo, ist die Mission verloren (im Briefing erklaert)")
	var bl := Battle.new()
	bl.setup(Mission.load_mission("ch8"), defs)
	root.add_child(bl)
	await process_frame
	var lost := []
	bl.finished.connect(func(w: bool) -> void: lost.append(w))
	var r2: Dictionary = bl._find("robo")
	bl.units.erase(r2)
	bl.fallen.append("robo")
	await bl._check_end()
	for i in 60:
		if not lost.is_empty():
			break
		await process_frame
	check(lost == [false], "Robo gefallen: Niederlage")
	check(b._count_team("e") > 0, "Die uebrigen Gegner leben noch, gewonnen ist trotzdem")
	check(b._hittable(tank), "Nach der Uebernahme ist Robina ein normales Ziel")
	var hr: Dictionary = defs["panzer"]
	check(hr.get("hero", false) and int(hr["from"]) == 9 and hr["role"] == "tank" and (hr["abilities"] as Array) == ["breitseite", "dampframme"], "Robina ist ein Held (ab Mission 9) mit Breitseite und Dampframme")

	# Breitseite des Panzers als Gegner
	b = null
	var b2 := Battle.new()
	b2.setup(Mission.load_mission("ch8"), defs)
	root.add_child(b2)
	await process_frame
	for u in b2.units.duplicate():
		(u["node"] as Node3D).queue_free()
	b2.units.clear()
	b2._spawn("ritter", "p", Vector2i(2, 8))
	var knight: Dictionary = b2.units.back()
	b2._spawn("panzer", "e", Vector2i(7, 8))
	var t2: Dictionary = b2.units.back()
	var hp0: int = knight["hp"]
	await b2._enemy_move(t2)
	check(knight["hp"] < hp0, "Der Panzer feuert die Breitseite auf den Helden (%d -> %d)" % [hp0, knight["hp"]])
	check(int(t2["cd"].get("breitseite", 0)) == 3, "Breitseite hat Abklingzeit")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
