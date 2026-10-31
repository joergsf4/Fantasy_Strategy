extends SceneTree
## godot --headless --path game --script tests/test_levelselect.gd
var fails := 0
var got: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var ls := LevelSelect.new()
	ls.setup([{"id": "ch1", "title": "Eins"}, {"id": "ch2", "title": "Zwei"}])
	ls.chosen.connect(func(i: int, skip: bool) -> void: got = [i, skip])
	root.add_child(ls)
	await process_frame
	var buttons: Array = ls.find_children("*", "Button", true, false)
	buttons = buttons.filter(func(b: Button) -> bool: return b.text != "Soundlabor" and b.text != "Spielstand zurücksetzen")
	check(buttons.size() == 4, "Zwei Kapitel mal zwei Knoepfe = 4, war %d" % buttons.size())
	check(buttons[0].text == "Mit Einleitung" and buttons[1].text == "Direkt in den Kampf", "Knopfbeschriftung")
	buttons[3].pressed.emit()
	check(got == [1, true], "Kapitel 2, direkt in den Kampf: %s" % [got])
	await process_frame
	check(not is_instance_valid(ls) or ls.is_queued_for_deletion(), "Auswahl schliesst sich")
	var m1 := Mission.load_mission("ch1")
	var m2 := Mission.load_mission("ch2")
	check(m1["id"] == "ch1" and m2["id"] == "ch2", "Missionen tragen ihre ID (Kapitelwechsel erkennt die Karte daran)")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
