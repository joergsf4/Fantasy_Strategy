extends SceneTree
## godot --headless --path game --script tests/test_squad_select.gd
## Gruppenwahl vor der Runde: Story-Figuren gesperrt, freie Plaetze tauschbar, nur wo es etwas zu waehlen gibt.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var party := Party.new_game()
	var m1 := Mission.load_mission("ch1")
	var m5 := Mission.load_mission("ch5")
	check(SquadSelect.has_choice(party, defs, m1), "Kapitel 1: elf Helden, sechs Plaetze: es gibt eine Wahl")
	check(not SquadSelect.has_choice(party, defs, {"id": "ch1", "players": m1["players"].slice(0, 0)}), "ohne Plaetze keine Wahl")
	check(SquadSelect.has_choice(party, defs, m5), "Kapitel 5: freie Plaetze und Ersatz vorhanden")
	var s := SquadSelect.new()
	s.setup(party, defs, m5)
	root.add_child(s)
	await process_frame
	var fixed: Array = Mission.dialogue_ids("ch5")
	var buttons: Array = s.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.contains("Story") or b.text == "Tauschen")
	check(buttons.size() == s.squad.size(), "ein Knopf je Platz (%d)" % buttons.size())
	for i in s.squad.size():
		var b: Button = buttons[i]
		check(b.disabled == fixed.has(s.squad[i]), "%s: gesperrt genau dann, wenn Story-Figur" % s.squad[i])
	# freien Platz waehlen und tauschen
	var free_i := -1
	for i in s.squad.size():
		if not fixed.has(s.squad[i]):
			free_i = i
	buttons[free_i].pressed.emit()
	await process_frame
	var cand: Array = s.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == defs["robo"]["name"])
	check(cand.size() == 1, "Ersatzheld Robo wird angeboten")
	cand[0].pressed.emit()
	await process_frame
	check(s.squad[free_i] == "robo" and party.squad_for(m5)[free_i] == "robo", "Tausch landet in der Gruppe der Mission")
	# gesperrter Platz laesst sich auch ueber die Party nicht tauschen
	var fixed_i := s.squad.find("ritter")
	check(not party.set_squad_member(m5, fixed_i, "hund"), "Story-Platz bleibt gesperrt")
	var closed := [false]
	s.closed.connect(func() -> void: closed[0] = true)
	var go: Array = s.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Los geht's")
	go[0].pressed.emit()
	check(closed[0], "Los geht's schliesst die Wahl")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
