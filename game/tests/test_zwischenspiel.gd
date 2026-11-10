extends SceneTree
## godot --headless --path game --script tests/test_zwischenspiel.gd
## Kapitel 17 (Zwischenspiel nach Mission 16, Frischlinge entfuehren den Sack): Reihenfolge, Haendlerwechsel (Sack bis 16, keiner bis 19, Morgrim danach),
## Spielstand-Umrechnung der Kapitel 17 und 18, Lager ohne Haendler und die 3D-Sequenz bis zum Ende.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_src.contains('"ch16", "ch17", "ch18", "ch19", "ch20", "ch21", "ch22", "ch23", "ch24", "ch25", "ch26"]'), "Kapitelliste bis ch26")
	var m := Mission.load_mission("ch17")
	check(m.get("stub", false) and m.get("camp_after", false) and m["interlude"]["scene"] == "berge", "ch17: Zwischenspiel ohne Kampf, Lager danach, Bergszene")
	check(Mission.load_mission("ch18")["title"] == "Die Wölfe der Nacht" and Mission.load_mission("ch19")["title"] == "Der Regent im Schnee", "Wölfe sind 18, Regent 19")
	check(Progression.missions_done_before(16) == 14 and Progression.missions_done_before(18) == 15 and Progression.missions_done_before(19) == 16, "Kampfmissionen vor 16, 18, 19 (zwei Zwischenspiele)")
	check(int(defs["alphawolf"]["from"]) == 19, "Alphawölfin ab Mission 19")
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_ch17.json"))
	var lines := Mission.voiced(story["intro"], ["maedchen_baer", "hund", "elisabeth"])
	check(lines.any(func(l: Dictionary) -> bool: return l["speaker"] == "hund") and lines.all(func(l: Dictionary) -> bool: return defs.has(l["speaker"])), "Stimmen der Gruppe sprechen, alle Sprecher existieren")
	check(not lines.any(func(l: Dictionary) -> bool: return l["speaker"] == "museklaugust"), "wer nicht dabei ist, spricht nicht")

	# Haendlerwechsel
	var p := Party.new_game()
	for c in [1, 8, 16]:
		p.chapter = c
		check(p.merchant().get("id", "") == "sack", "Kapitel %d: Sack handelt" % c)
	for c in [17, 18, 19]:
		p.chapter = c
		check(p.merchant().is_empty() and p.stock().is_empty(), "Kapitel %d: kein Haendler, kein Sortiment" % c)
	p.chapter = 20
	check(p.merchant().get("id", "") == "morgrim" and p.merchant().get("portrait", "") == "fuerst_lumpen", "nach Mission 19 handelt Morgrim")
	var ids: Array = p.stock().map(func(w: Dictionary) -> String: return w["id"])
	check(ids.has("runenschwert") and ids.has("drachenzahn") and ids.has("heiltrank") and ids.size() == 8, "Morgrims Truhe: %s" % [ids])
	p.gold = 1000
	check(p.buy("runenschwert") and p.pool.has("runenschwert") and not p.buy("runenschwert"), "Kaufen bei Morgrim, nur einmal")
	p.chapter = 16
	var sack_price := 0
	for w: Dictionary in p.stock():
		if w["id"] == "runenschwert":
			sack_price = int(w["price"])
	check(sack_price == 420, "Sack verlangt 420 fuer das Runenschwert, Morgrim 460 (Preise aus besseren Tagen)")
	check(ResourceLoader.exists("res://assets/portraits/haendler.png") and ResourceLoader.exists("res://assets/portraits/fuerst_lumpen.png"), "Portraits der Haendler")

	# Spielstand von vor dem Zwischenspiel
	var old := Party.from_dict({"chapter": 17, "squads": {"ch5": ["hund"], "ch17": ["wendy"], "ch18": ["robo"]}})
	check(old.chapter == 18 and old.squads.has("ch5") and old.squads["ch18"] == ["wendy"] and old.squads["ch19"] == ["robo"] and not old.squads.has("ch17"), "alter Spielstand rueckt nach: %s" % [old.squads])
	check(Party.from_dict({"chapter": 16}).chapter == 16, "Spielstand vor Kapitel 17 bleibt")
	check(Party.from_dict(old.to_dict()).chapter == 18, "neuer Spielstand wird nicht doppelt umgerechnet")

	# Lager ohne Haendler
	var camp_party := Party.new_game()
	camp_party.chapter = 18
	var camp := Camp.new()
	camp.setup(camp_party, defs, ["maedchen_baer", "hund", "ritter"], Mission.load_mission("ch18"))
	root.add_child(camp)
	await process_frame
	check(not camp._nav["haendler"].visible and camp._page == "uebersicht" and camp._nav["ausruestung"].visible, "Lager ohne Haendler: Haendlerseite fehlt, die Uebersicht ist die erste Seite")
	camp.queue_free()
	var camp2 := Camp.new()
	var cp2 := Party.new_game()
	cp2.chapter = 20
	camp2.setup(cp2, defs, ["maedchen_baer"], Mission.load_mission("ch19"))
	root.add_child(camp2)
	await process_frame
	camp2.show_page("haendler")
	check(camp2._nav["haendler"].visible and camp2._page == "haendler", "Lager mit Morgrim: Haendlerseite da")
	camp2.queue_free()

	# Sequenz laeuft bis zum Ende
	var raid := MountainRaid.new()
	raid.setup({"duration": 27.0, "party": ["maedchen_baer", "ritter", "hund", "elisabeth", "robo"]})
	root.add_child(raid)
	var done := {"v": false}
	raid.finished.connect(func() -> void: done["v"] = true)
	var frames := 0
	while not done["v"] and frames < 3000:
		frames += 1
		await process_frame
	check(done["v"], "Bergszene endet von selbst (%d Bilder)" % frames)
	check(raid._said.has("rush") and raid._poofed and raid._exclaimed, "Hinterhalt, Entfuehrung und Schrecken sind gelaufen")
	raid._wind.stop()
	for player: AudioStreamPlayer in Sfx.get_inst()._players:
		player.stop()
	raid.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	await create_timer(0.2).timeout
	print("zwischenspiel: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
