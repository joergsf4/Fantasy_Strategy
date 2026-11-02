extends SceneTree
## godot --headless --path game --script tests/test_interlude.gd
## Kapitel 2 (ch10): Zwischenspiel ohne Kampf mit Reisebild (Ken Burns, Titelkarte) und Hafen-Gespraech.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch10")
	check(m.get("stub", false) and m["interlude"]["kicker"] == "Kapitel 2", "ch10 ist ein Zwischenspiel mit Titelkarte")
	check(ResourceLoader.exists(m["interlude"]["image"]), "Reisebild vorhanden")
	for id: String in Mission.dialogue_ids("ch10"):
		check(defs.has(id), "Sprecher %s existiert" % id)
	var it := Interlude.new()
	it.setup(m["interlude"])
	it.duration = 2.0
	root.add_child(it)
	var done := []
	it.finished.connect(func() -> void: done.append(1))
	await create_timer(0.3).timeout
	check(done.is_empty(), "Zwischenspiel laeuft noch")
	await create_timer(2.3).timeout
	check(done.size() == 1, "Zwischenspiel endet nach der Dauer genau einmal")
	var it2 := Interlude.new()
	it2.setup(m["interlude"])
	root.add_child(it2)
	var done2 := []
	it2.finished.connect(func() -> void: done2.append(1))
	await create_timer(0.8).timeout
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_SPACE
	it2._unhandled_input(ev)
	check(done2.size() == 1, "Taste ueberspringt")
	print("interlude: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
