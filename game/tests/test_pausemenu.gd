extends SceneTree
## godot --headless --path game --script tests/test_pausemenu.gd
## Pause-Menue: "Zum Hauptmenue" nur im laufenden Spiel, mit Rueckfrage; Bestaetigen meldet menu_requested.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _texts(m: Control) -> Array:
	return m.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)


func _initialize() -> void:
	var a := PauseMenu.new()
	a.can_save = false
	root.add_child(a)
	await process_frame
	check(not _texts(a).has("Zum Hauptmenü"), "Im Hauptmenue selbst kein Rueckweg: %s" % [_texts(a)])
	a.close()
	var b := PauseMenu.new()
	b.can_save = true
	root.add_child(b)
	await process_frame
	check(_texts(b).has("Zum Hauptmenü") and _texts(b).has("Beenden"), "Im Spiel: Hauptmenue und Beenden: %s" % [_texts(b)])
	var got := []
	b.menu_requested.connect(func() -> void: got.append(1))
	for bt: Button in b.find_children("*", "Button", true, false):
		if bt.text == "Zum Hauptmenü":
			bt.pressed.emit()
			break
	await process_frame
	check(got.is_empty() and _texts(b).has("Ja, zum Hauptmenü"), "Erst Rueckfrage")
	for bt: Button in b.find_children("*", "Button", true, false):
		if bt.text == "Ja, zum Hauptmenü":
			bt.pressed.emit()
			break
	check(got.size() == 1, "Bestaetigen meldet menu_requested")
	# Mission neu starten: nur im Kampf, mit Rueckfrage
	check(not _texts(b).has("Mission neu starten"), "Ohne Kampf kein Neustart-Knopf")
	var c := PauseMenu.new()
	c.can_save = true
	c.can_restart = true
	root.add_child(c)
	await process_frame
	check(_texts(c).has("Mission neu starten"), "Im Kampf: Mission neu starten: %s" % [_texts(c)])
	var rgot := []
	c.restart_requested.connect(func() -> void: rgot.append(1))
	for bt: Button in c.find_children("*", "Button", true, false):
		if bt.text == "Mission neu starten":
			bt.pressed.emit()
			break
	await process_frame
	check(rgot.is_empty() and _texts(c).has("Ja, neu starten"), "Erst Rueckfrage")
	for bt: Button in c.find_children("*", "Button", true, false):
		if bt.text == "Ja, neu starten":
			bt.pressed.emit()
			break
	check(rgot.size() == 1, "Bestaetigen meldet restart_requested")
	print("pausemenu: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
