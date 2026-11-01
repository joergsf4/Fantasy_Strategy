extends SceneTree
## godot --headless --path game --script tests/test_title.gd
## Hauptmenue (Fortfahren / Neues Spiel / Beenden, Sicherheitsabfrage, Cheat "brumm") und Pause-Menue (Esc: Weiter, Speichern, Vollbild, Beenden).

var fails := 0
var chosen: Array = []
var saved := 0
var quits := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func key(t: Node, ch: String) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.unicode = ch.unicode_at(0)
	ev.keycode = ch.to_upper().unicode_at(0)
	t._unhandled_input(ev)


func buttons(n: Node) -> Dictionary:
	var out := {}
	for b: Button in n.find_children("*", "Button", true, false):
		out[b.text] = b
	return out


func make(save_chapter: int, interactive := true) -> TitleScreen:
	var t := TitleScreen.new()
	t.save_chapter = save_chapter
	t.interactive = interactive
	t.chosen.connect(func(a: String) -> void: chosen.append(a))
	root.add_child(t)
	return t


func _initialize() -> void:
	Engine.time_scale = 10.0
	# --- Hauptmenue mit Spielstand
	var t := make(3)
	await create_timer(5.0).timeout
	var bt := buttons(t)
	check(bt.has("Fortfahren (Kapitel 3)") and bt.has("Neues Spiel") and bt.has("Beenden"), "Menue: Fortfahren, Neues Spiel, Beenden: %s" % [bt.keys()])
	for c in "BRUMM":
		key(t, c)
	check(not t.cheat, "Grossbuchstaben schalten nichts frei")
	for c in "brumm":
		key(t, c)
	check(t.cheat and chosen.is_empty(), "brumm (klein) schaltet die Kapitelwahl frei, Buchstaben starten nichts")
	bt["Neues Spiel"].pressed.emit()
	await process_frame
	check(chosen.is_empty() and buttons(t).has("Ja, neu beginnen"), "Neues Spiel fragt nach, solange ein Spielstand da ist")
	buttons(t)["Zurück"].pressed.emit()
	await process_frame
	check(not buttons(t).has("Ja, neu beginnen") and chosen.is_empty(), "Zurueck bricht ab")
	bt["Neues Spiel"].pressed.emit()
	await process_frame
	buttons(t)["Ja, neu beginnen"].pressed.emit()
	await create_timer(2.0).timeout
	check(chosen == ["new"], "Ja startet ein neues Spiel: %s" % [chosen])
	t.queue_free()

	# --- ohne Spielstand: kein Fortfahren, Neues Spiel ohne Rueckfrage
	chosen.clear()
	var t2 := make(0)
	await create_timer(5.0).timeout
	var b2 := buttons(t2)
	check(not b2.keys().any(func(k: String) -> bool: return k.begins_with("Fortfahren")) and b2.has("Neues Spiel"), "ohne Spielstand nur Neues Spiel und Beenden")
	b2["Neues Spiel"].pressed.emit()
	await create_timer(2.0).timeout
	check(chosen == ["new"], "Neues Spiel ohne Rueckfrage")
	t2.queue_free()
	chosen.clear()
	var t3 := make(2)
	await create_timer(5.0).timeout
	buttons(t3)["Fortfahren (Kapitel 2)"].pressed.emit()
	await create_timer(2.0).timeout
	check(chosen == ["continue"], "Fortfahren")
	t3.queue_free()

	# --- Pause-Menue
	var pm := PauseMenu.new()
	pm.can_save = true
	pm.save_requested.connect(func() -> void: saved += 1)
	pm.quit_requested.connect(func() -> void: quits += 1)
	root.add_child(pm)
	await process_frame
	check(paused, "Pause-Menue haelt das Spiel an")
	var bp := buttons(pm)
	check(bp.has("Weiter") and bp.has("Speichern") and bp.keys().any(func(k: String) -> bool: return k.begins_with("Vollbild")) and bp.has("Beenden"), "Menue: %s" % [bp.keys()])
	check(not bp["Speichern"].disabled, "Speichern ist moeglich")
	bp["Speichern"].pressed.emit()
	check(saved == 1, "Speichern meldet sich")
	bp["Beenden"].pressed.emit()
	await process_frame
	check(quits == 0 and buttons(pm).has("Ja, beenden"), "Beenden fragt nach")
	buttons(pm)["Zurück"].pressed.emit()
	await process_frame
	buttons(pm)["Beenden"].pressed.emit()
	await process_frame
	buttons(pm)["Ja, beenden"].pressed.emit()
	check(quits == 1, "Ja beendet")
	pm.close()
	await process_frame
	check(not paused, "Weiter hebt die Pause auf")
	var pm2 := PauseMenu.new()
	pm2.can_save = false
	root.add_child(pm2)
	await process_frame
	check(buttons(pm2)["Speichern"].disabled, "im Hauptmenue ist Speichern gesperrt")
	pm2.close()
	await process_frame

	# --- Esc ueber den PauseHost
	var host := PauseHost.new()
	root.add_child(host)
	await process_frame
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.keycode = KEY_ESCAPE
	host._input(esc)
	await process_frame
	check(host.is_open() and paused, "Esc oeffnet das Menue")
	host._input(esc)
	await process_frame
	check(not host.is_open() and not paused, "Esc schliesst es wieder")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
