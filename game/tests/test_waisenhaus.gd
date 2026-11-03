extends SceneTree
## godot --headless --path game --script tests/test_waisenhaus.gd
## Mission 14: Das Waisenhaus brennt, zwei Runden zum Loeschen, sonst verloren; Stachelia greift in Runde 4 ein. Mission 13: Cyborg-Wart bricht am Ende immer aus.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _make(defs: Dictionary, ch: String) -> Battle:
	var b := Battle.new()
	b.setup(Mission.load_mission(ch), defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	return b


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch14")
	check((m["players"] as Array).size() == 5, "Mission 14 startet mit fuenf Helden")
	for id: String in Mission.dialogue_ids("ch14"):
		check(defs.has(id) or id == "waisenkinder", "Sprecher %s existiert" % id)
	check(not Party.roster(defs, 14, true).has("bienenmaedchen"), "Stachelia ist in Mission 14 nicht waehlbar (sie stoesst im Kampf dazu)")
	var b := _make(defs, "ch14")
	await process_frame
	var h := b.world.by_id("waisenhaus")
	check(h["state"] == "intact" and int(h["burn"]) == 2, "Waisenhaus heil, brennt nur zwei Runden")
	# Runde 2: Zwillinge zuenden an
	b.turn = 2
	await b._run_triggers("turn", 2)
	check(h["state"] == "burning", "Waisenhaus brennt ab Runde 2")
	# Eine Feuerphase: brennt noch; zweite: abgebrannt, Mission verloren
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._fire_phase()
	check(h["state"] == "burning" and not b.state == Battle.State.OVER, "Nach der ersten Feuerphase brennt es noch (zwei Runden Zeit)")
	await b._fire_phase()
	check(h["state"] == "ruin", "Nach der zweiten Feuerphase ist es abgebrannt")
	await create_timer(2.0).timeout
	check(got == [false], "Waisenhaus abgebrannt: Mission verloren: %s" % [got])
	# Geloescht rettet es
	var b2 := _make(defs, "ch14")
	await process_frame
	var h2 := b2.world.by_id("waisenhaus")
	b2.turn = 2
	await b2._run_triggers("turn", 2)
	await b2._fire_phase()
	await b2._after_world_change(b2.world.apply(h2, "extinguish"))
	await b2._fire_phase()
	check(h2["state"] == "intact" and b2.state != Battle.State.OVER, "Geloescht: Waisenhaus bleibt, Kampf geht weiter")
	# Runde 4: Stachelia stoesst als sechste Heldin dazu
	var before := b2._count_team("p")
	b2.turn = 4
	await b2._run_triggers("turn", 4)
	var st := b2._find("bienenmaedchen")
	check(not st.is_empty() and st["team"] == "p" and b2._count_team("p") == before + 1 and said.has("bienenmaedchen"), "Stachelia greift in Runde 4 ein und kaempft mit")
	# Mission 13: Cyborg-Wart bricht am Ende immer aus
	said.clear()
	var b3 := _make(defs, "ch13")
	await process_frame
	check(b3._find("cyborg_wart").is_empty() and b3.world.by_id("zylinder")["state"] == "intact", "Mission 13: Behaelter zu Beginn heil")
	for id in ["kind1", "kind2", "kind3"]:
		b3.world.by_id(id)["state"] = "free"
	await b3._check_end()
	check(b3.world.by_id("zylinder")["state"] == "broken" and not b3._find("cyborg_wart").is_empty() and said.has("cyborg_wart"), "Mission 13: Cyborg-Wart bricht am Ende trotzdem aus: %s" % [said])
	print("waisenhaus: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
