extends SceneTree
## godot --headless --path game --script tests/test_dialog_click.gd
## Linksklick schaltet Dialoge weiter: im normalen Dialog und im Dialog ueber einer abgedunkelten Karte (mitten im Kampf).

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func click(pos := Vector2(640, 360), button := MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		Input.parse_input_event(ev)
	await process_frame
	await process_frame


func _initialize() -> void:
	var lines := [
		{"left": "ritter", "speaker": "ritter", "text": "Eins"},
		{"left": "ritter", "speaker": "ritter", "text": "Zwei"},
		{"left": "ritter", "speaker": "ritter", "text": "Drei"}]
	var names := {"ritter": "Albrecht"}
	for variant in ["normal", "ueber_abdunkelung"]:
		var layer := CanvasLayer.new()
		root.add_child(layer)
		if variant == "ueber_abdunkelung":   # wie _battle_dialogue in main.gd
			var dim := ColorRect.new()
			dim.color = Color(0, 0, 0, 0.5)
			dim.set_anchors_preset(Control.PRESET_FULL_RECT)
			layer.add_child(dim)
		var d := Dialogue.new()
		d.setup(lines, names)
		layer.add_child(d)
		await process_frame
		await process_frame
		check(d._idx == 0, "%s: Start bei Zeile 0" % variant)
		await click()   # 1. Klick: Text sofort ganz zeigen
		check(d._idx == 0 and not d._typing, "%s: erster Klick zeigt den Rest des Textes" % variant)
		await click()   # 2. Klick: naechste Zeile
		check(d._idx == 1, "%s: zweiter Klick -> Zeile 2 (war %d)" % [variant, d._idx])
		await click(Vector2(100, 600))   # Klick auf die Textbox
		await click(Vector2(100, 600))
		check(d._idx == 2, "%s: Klick auf die Textbox schaltet ebenfalls weiter (war %d)" % [variant, d._idx])
		await click(Vector2(640, 360), MOUSE_BUTTON_RIGHT)
		check(d._idx == 2, "%s: Rechtsklick tut nichts" % variant)
		var done := [false]
		d.finished.connect(func() -> void: done[0] = true)
		await click()
		await click()
		check(done[0], "%s: Dialog endet nach der letzten Zeile" % variant)
		layer.queue_free()
		await process_frame
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
