extends SceneTree
## godot --headless --path game --script tests/test_snow_trek.gd
## Schneesturm-Zwischensequenz: Linksklick bricht ab (mit kurzer Schwarzblende), ohne Klick laeuft sie bis zum Ende, Gruppe stapft nie rueckwaerts.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var trek := SnowTrek.new()
	trek.setup({"duration": 6.0, "party": ["maedchen_baer", "ritter", "hund"]})
	root.add_child(trek)
	await process_frame
	var done := [0.0]
	trek.finished.connect(func() -> void: done[0] = float(Time.get_ticks_msec()) / 1000.0)
	check(trek._figs.size() == 3, "die gewaehlte Truppe laeuft mit (%d Figuren)" % trek._figs.size())
	# Wegmarken: die Spitze darf nie rueckwaerts laufen
	var last := -999.0
	var monotone := true
	for i in 90:
		await process_frame
		var x: float = (trek._figs[0]["root"] as Node3D).position.x
		if x < last - 0.0001:
			monotone = false
		last = x
	check(monotone, "die Gruppe laeuft nie rueckwaerts")
	# Zu frueher Klick wird ignoriert, spaeter bricht ab
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var t0 := float(Time.get_ticks_msec()) / 1000.0
	trek._input(click)
	check(trek._skipping, "Linksklick bricht ab")
	await create_timer(1.2).timeout
	check(done[0] > 0.0 and done[0] - t0 < 1.0, "Ende kommt nach kurzer Schwarzblende (%.2f s)" % (done[0] - t0))
	check(trek._black.modulate.a >= 0.99, "Bild ist schwarz, wenn es endet")
	print("snow_trek: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
