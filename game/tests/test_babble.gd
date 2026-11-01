extends SceneTree
## godot --headless --path game --script tests/test_babble.gd
## Brabbel-Laute: jede Figur hat eine Stimme, beim Tippen klingt es bei jedem zweiten Buchstaben, Ueberspringen und Satzzeichen bleiben still.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var s := Sfx.get_inst()
	await process_frame
	Sfx.muted = true
	var voices: Dictionary = s.cfg["voices"]
	var units: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for id: String in units:
		if not id.begins_with("_") and units[id].get("hero", false):
			check(voices.has(id), "Held %s hat eine Stimme" % id)
	for id: String in voices:
		check(ResourceLoader.exists("%s%s_1.wav" % [Sfx.DIR, voices[id]["s"]]), "Stimme %s: Klang %s existiert" % [id, voices[id]["s"]])
	s.played.clear()
	Sfx.babble("robo")
	Sfx.babble("gibtsnicht")
	check(s.played == ["v_robot", "v_mid"], "Robo piept, Unbekannte bekommen die Standardstimme: %s" % [s.played])
	# Dialogzeile: "Hallo Welt!" hat 9 Buchstaben -> Laute bei Buchstabe 1, 3, 5, 7, 9
	var d := Dialogue.new()
	d.setup([{"left": "wendy", "right": "robo", "speaker": "wendy", "text": "Hallo Welt!"}], {"wendy": "Wendy", "robo": "Robo"})
	root.add_child(d)
	s.played.clear()
	await create_timer(1.0).timeout
	var blips: Array = s.played.filter(func(n: String) -> bool: return n == "v_bleat")
	check(blips.size() == 5, "Wendy bleckt 5-mal bei 9 Buchstaben (%d)" % blips.size())
	d.queue_free()
	# Ueberspringen: kein Laut mehr
	var d2 := Dialogue.new()
	d2.setup([{"left": "wendy", "right": "robo", "speaker": "robo", "text": "Piep piep piep piep piep piep"}], {"robo": "Robo", "wendy": "Wendy"})
	root.add_child(d2)
	await process_frame
	s.played.clear()
	d2._advance()      # Tippen beenden
	await create_timer(0.5).timeout
	check(s.played.filter(func(n: String) -> bool: return n == "v_robot").is_empty(), "nach dem Ueberspringen bleibt es still")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
