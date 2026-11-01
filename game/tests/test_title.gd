extends SceneTree
## godot --headless --path game --script tests/test_title.gd
## Hauptmenue: Cheat "brumm" (klein) schaltet die Kapitelwahl frei, Buchstaben starten das Spiel nicht, N-N = neues Spiel.

var fails := 0
var started := 0
var new_games := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func key(t: TitleScreen, ch: String) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.unicode = ch.unicode_at(0)
	ev.keycode = ch.to_upper().unicode_at(0)
	t._unhandled_input(ev)


func special(t: TitleScreen, keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = keycode
	t._unhandled_input(ev)


func make(save_chapter: int) -> TitleScreen:
	var t := TitleScreen.new()
	t.save_chapter = save_chapter
	t.started.connect(func() -> void: started += 1)
	t.new_game_requested.connect(func() -> void: new_games += 1)
	root.add_child(t)
	t._ready_for_input = true
	return t


func _initialize() -> void:
	Engine.time_scale = 10.0
	var t := make(0)
	await process_frame
	for c in "BRUMM":
		key(t, c)
	check(not t.cheat, "Grossbuchstaben schalten nichts frei")
	for c in "xbrum":
		key(t, c)
	check(not t.cheat, "unvollstaendiges Wort schaltet nichts frei")
	key(t, "m")
	check(t.cheat, "brumm (klein) schaltet die Kapitelwahl frei")
	check(started == 0, "Buchstaben starten das Spiel nicht")
	key(t, "n")
	check(new_games == 0, "ohne Spielstand tut N nichts")
	special(t, KEY_ENTER)
	await create_timer(1.2).timeout
	check(started == 1, "Enter startet")
	t.queue_free()

	var t2 := make(3)
	await process_frame
	key(t2, "n")
	check(new_games == 0, "ein N fragt nur nach")
	key(t2, "n")
	check(new_games == 1 and t2.save_chapter == 0, "zweites N startet ein neues Spiel")
	special(t2, KEY_SPACE)
	await create_timer(1.2).timeout
	check(started == 2 and not t2.cheat, "Leertaste startet ohne Cheat")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
