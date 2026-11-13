extends SceneTree
## godot --headless --path game --script tests/test_play_bot.gd
## Bausteine des Spieltest-Bots (scripts/bot/): Hinweisdatei gueltig, Aufbau eines Kapitels, Menue-Abgleich ohne Planabweichung,
## gleiches Ergebnis bei gleichem Start (Reproduzierbarkeit), gesperrte Faehigkeiten werden nicht benutzt.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 40.0
	Sfx.muted = true
	var defs := BotSetup.defs()
	var missions := BotSetup.battle_missions()
	check(missions.has("ch1") and missions.has("ch25") and not missions.has("ch10") and missions.find("rb_takeda") == missions.find("ch3") + 1,
		"Kampfmissionen in Spielreihenfolge, ohne Kapitel ohne Kampf, Rueckblende nach Mission 3")
	# Hinweise: nur bekannte Missionen, Objekte und Figuren
	var hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/bot_hints.json"))
	for cid: String in hints:
		if cid.begins_with("_"):
			continue
		check(missions.has(cid), "Hinweis fuer unbekannte Mission " + cid)
		check(str(hints[cid].get("note", "")) != "", "Hinweis %s ohne Begruendung (note)" % cid)
		if not missions.has(cid):
			continue
		var m := Mission.load_mission(cid)
		var obj_ids: Array = (m.get("objects", []) as Array).map(func(o: Dictionary) -> String: return str(o.get("id", "")))
		for h: Dictionary in hints[cid].get("objectives", []):
			check(obj_ids.has(str(h.get("object", ""))), "Hinweis %s: Objekt %s fehlt auf der Karte" % [cid, h.get("object", "")])
			check(not h.has("by") or defs.has(str(h["by"])), "Hinweis %s: Figur %s unbekannt" % [cid, h.get("by", "")])
	# Aufbau: Kapitel 8 mit erwarteter Stufe, Rueckblende mit dem Aufstieg aus Kapitel 3
	var p8: Dictionary = BotSetup.prepare(defs, "ch8")
	check((p8["squad"] as Array).has("robo") and (p8["party"] as Party).earned == Progression.missions_done_before(8), "Kapitel 8: Robo dabei, erwartete Stufe")
	var prb: Dictionary = BotSetup.prepare(defs, "rb_takeda")
	check(p8["squad"] != prb["squad"] and (prb["squad"] as Array) == ["samurai"], "Rueckblende: nur Takeda")
	check((BotSetup.prepare(defs, "ch3")["party"] as Party).nemesis.has("wart"), "Kapitel 3: Wart kehrt zurueck (in Mission 2 geflohen)")
	var none: Dictionary = BotSetup.prepare(defs, "ch8", {"gear": "none", "talents": {"mode": "zero"}})
	check((none["party"] as Party).equipment.is_empty() and int((none["party"] as Party).talents["robo"]["atk"]) == 0, "Variante ohne Ausruestung und Talente")
	# Spielen: ohne Planabweichung, reproduzierbar
	var r1 := await _play(defs, "ch6", {})
	var r2 := await _play(defs, "ch6", {})
	check(r1["won"], "Mission 6 geschafft: %s" % r1["reason"])
	check((r1["mismatches"] as Array).is_empty(), "keine Planabweichung: %s" % [r1["mismatches"]])
	check(r1["turns"] == r2["turns"] and r1["survivors"] == r2["survivors"] and is_equal_approx(r1["hp_ratio"], r2["hp_ratio"]), "gleicher Start, gleiches Ergebnis")
	check(not (r1["abilities_used"] as Dictionary).is_empty() and not (r1["abilities_offered"] as Dictionary).is_empty(), "Faehigkeiten angeboten und benutzt")
	# Sperre: Elisabeths Breitseite wird nicht benutzt, obwohl sie angeboten wird
	var r3 := await _play(defs, "ch6", {"elisabeth": ["breitseite"]})
	check(not ((r3["abilities_used"] as Dictionary).get("elisabeth", {}) as Dictionary).has("breitseite"), "gesperrte Faehigkeit bleibt ungenutzt")
	print("play_bot: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)


func _play(defs: Dictionary, cid: String, banned: Dictionary) -> Dictionary:
	var b := await BotSetup.build(root, defs, cid)
	var bot := PlayBot.new(b, {"banned": banned})
	var res := await bot.play()
	b.queue_free()
	await process_frame
	return res
