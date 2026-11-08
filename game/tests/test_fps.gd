extends SceneTree
## godot --headless --path game --script tests/test_fps.gd
## Laptops schonen: Bildrate ab Werk 60 (statt unbegrenzt), Schatten ab Werk Mittel, alte Werkswerte werden einmal umgestellt,
## im Hintergrund nur wenige Bilder pro Sekunde.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var tmp := "user://test_fps_settings.cfg"
	Settings.values.clear()
	check(Settings.get_value("fps") == 1 and Settings.value_text("fps") == "60", "Bildrate ab Werk 60")
	check(Settings.value_text("shadows") == "Mittel", "Schatten ab Werk Mittel")
	# alte Datei (Version 1) mit den alten Werkswerten: wird einmal umgestellt
	var old := ConfigFile.new()
	old.set_value("grafik", "fps", 3)
	old.set_value("grafik", "shadows", 3)
	old.save(tmp)
	Settings.values.clear()
	Settings.load_file(tmp)
	check(Settings.get_value("fps") == 1 and Settings.get_value("shadows") == 2, "alte Werkswerte werden umgestellt")
	var cf := ConfigFile.new()
	cf.load(tmp)
	check(int(cf.get_value("grafik", "version", 1)) == Settings.VERSION, "Umstellung wird gespeichert (nur einmal)")
	# neue Datei: eine bewusst gewaehlte unbegrenzte Bildrate bleibt
	Settings.set_value("fps", 3)
	Settings.save_file(tmp)
	Settings.values.clear()
	Settings.load_file(tmp)
	check(Settings.get_value("fps") == 3, "bewusst gewaehlte Bildrate bleibt nach der Umstellung erhalten")
	# Hintergrund-Drosselung
	Settings.set_focused(false)
	check(not Settings.focused, "Fenster im Hintergrund erkannt")
	Settings.set_focused(true)
	check(Settings.focused, "Fenster wieder im Vordergrund")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	print("fps: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
