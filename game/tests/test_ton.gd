extends SceneTree
## godot --headless --path game --script tests/test_ton.gd
## Reiter "Ton und Spiel": Lautstaerke von Musik und Effekten auf eigenen Bussen, Schwierigkeit als Faktor auf die Gegner,
## Helligkeit und Kontrast im Reiter "Grafik".

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	Settings.values.clear()
	check(Settings.get_value("music") == 8 and Settings.get_value("sfx") == 8 and Settings.get_value("difficulty") == 1, "Werkswerte: Musik und Effekte 80 %, Normal")
	var mb := Settings.music_bus()
	check(mb > 0 and AudioServer.get_bus_name(mb) == Settings.MUSIC_BUS, "Musik-Bus angelegt")
	Settings.set_value("music", 0)
	Settings.apply_audio()
	check(AudioServer.is_bus_mute(mb), "Musik aus: Bus stumm")
	Settings.set_value("music", 10)
	Settings.apply_audio()
	check(not AudioServer.is_bus_mute(mb) and absf(AudioServer.get_bus_volume_db(mb)) < 0.01, "Musik 100 %: 0 dB")
	Settings.set_value("music", 5)
	Settings.apply_audio()
	check(AudioServer.get_bus_volume_db(mb) < -5.0, "Musik 50 %: leiser")
	# Schwierigkeit wirkt auf neue Gegner
	var hp := {}
	for lvl in [0, 1, 2]:
		Settings.set_value("difficulty", lvl)
		var b := Battle.new()
		b.setup(Mission.load_mission("ch2"), defs)
		root.add_child(b)
		await process_frame
		var e: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e")[0]
		hp[lvl] = int(e["maxhp"])
		b.queue_free()
		await process_frame
	check(hp[0] < hp[1] and hp[1] < hp[2], "Leicht < Normal < Schwer: %s" % [hp])
	Settings.set_value("difficulty", 1)
	# Helligkeit und Kontrast
	Settings.set_value("brightness", 4)
	Settings.set_value("contrast", 0)
	check(absf(Settings.brightness() - 1.2) < 0.001 and absf(Settings.contrast() - 0.8) < 0.001, "Helligkeit +20 %, Kontrast −20 %")
	var b2 := Battle.new()
	b2.setup(Mission.load_mission("ch1"), defs)
	root.add_child(b2)
	await process_frame
	check(b2._env != null and b2._env.adjustment_enabled and absf(b2._env.adjustment_brightness - 1.2) < 0.001, "Kampf übernimmt Helligkeit")
	Settings.set_value("brightness", 2)
	Settings.set_value("contrast", 2)
	b2.apply_adjustments()
	check(not b2._env.adjustment_enabled, "Normal: keine Anpassung")
	# Speichern und Laden
	var path := "user://test_ton.cfg"
	Settings.set_value("music", 3)
	Settings.set_value("difficulty", 2)
	Settings.save_file(path)
	Settings.values.clear()
	Settings.load_file(path)
	check(Settings.get_value("music") == 3 and Settings.get_value("difficulty") == 2, "Ton und Schwierigkeit werden gespeichert")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Settings.values.clear()
	print("ton: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
