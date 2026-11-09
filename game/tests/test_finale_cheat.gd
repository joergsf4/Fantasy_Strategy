extends SceneTree
## godot --headless --path game --script tests/test_finale_cheat.gd
## Testmenue "Finale: Sieg über den Sack": Knopf in der Kapitelwahl; Mission 25 beginnt direkt vor dem letzten Schlag
## (Honig drin, Professor weg, Xiùlán dabei, Sack mit 1 Leben neben Mira). Ein Schlag gewinnt die Mission.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var ls := LevelSelect.new()
	ls.setup([{"id": "ch24", "title": "A"}, {"id": "ch25", "title": "B"}, {"id": "ch26", "title": "C"}])
	root.add_child(ls)
	await process_frame
	var btn: Button = null
	for n: Node in ls.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with("Finale: Sieg über den Sack"):
			btn = n
	check(btn != null, "Knopf im Testmenue")
	var got := []
	ls.finale_end_requested.connect(func() -> void: got.append("finale"))
	ls.chosen.connect(func(i: int, skip: bool) -> void: got.append([i, skip]))
	btn.pressed.emit()
	check(got == ["finale", [1, true]], "Knopf waehlt Mission 25 direkt in den Kampf: %s" % [got])
	var b := Battle.new()
	b.setup(Mission.load_mission("ch25"), defs)
	b.dialogue_runner = func(_l: Array) -> void: pass
	root.add_child(b)
	await process_frame
	var mn: Node = load("res://scripts/main.gd").new()
	mn._setup_finale_end(b)
	var sack := b._find("sack_boss")
	var hero := b._find("maedchen_baer")
	check(not sack.is_empty() and sack["hp"] == 1, "nur noch der Sack mit 1 Leben")
	check(b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e").size() == 1, "keine anderen Gegner")
	check(b._find("kugelblitz").is_empty() and b.world.by_id("honigmaschine")["state"] == "filled", "Professor weg, Honig drin")
	check(not b._find("xiulan_gast").is_empty(), "Xiùlán ist dabei")
	check(Grid.dist(hero["pos"], sack["pos"]) == 1, "Mira steht direkt vor dem Sack")
	var won := []
	b.finished.connect(func(w: bool) -> void: won.append(w))
	await b._resolve(hero, sack)
	for i in 200:
		if not won.is_empty():
			break
		await process_frame
	check(won == [true], "ein Schlag gewinnt die Mission")
	mn.free()
	print("finale_cheat: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
