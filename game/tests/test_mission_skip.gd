extends SceneTree
## Mission ueberspringen nach zwei Niederlagen: Abschlussszenen laufen wie nach einem Sieg, Bonusziele zaehlen nicht.
var fails := 0


func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var seen: Array = []
	var b := Battle.new()
	b.setup(Mission.load_mission("ch16"), defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			seen.append(l["text"])
	root.add_child(b)
	await process_frame
	await b.skip_to_victory()
	check(seen.any(func(t: String) -> bool: return t.begins_with("Der Professor ist erledigt")), "Abschlussdialog von Mission 16 laeuft (%s)" % str(seen))
	var res := b.results()
	check(res.get("skipped", false), "Ergebnis ist als uebersprungen markiert")
	check((res["objectives"] as Array).is_empty(), "keine Bonusziele")
	var p := Party.new_game()
	var ch := p.chapter
	p.absorb(res)
	check(p.chapter == ch + 1 and p.earned == 1, "Geschichte und Stufe gehen weiter")
	b.queue_free()
	# Niederlage-Bildschirm: Knopf erst mit can_skip
	for cs in [false, true]:
		var r := RewardScreen.new()
		r.setup({"defeat": true, "can_skip": cs, "turns": 3, "objectives": [], "stats": {}})
		root.add_child(r)
		await process_frame
		var texts: Array = r.find_children("*", "Button", true, false).map(func(x: Button) -> String: return x.text)
		check(texts.has("Mission überspringen") == cs, "Knopf nur nach zwei Niederlagen (%s)" % str(texts))
		r.queue_free()
	print("mission_skip: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
