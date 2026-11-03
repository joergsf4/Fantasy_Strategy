extends SceneTree
## godot --headless --path game --script tests/test_settings.gd
## Grafikoptionen: Standardwerte, Wechsel, Voreinstellungen, Speichern und Laden, Pause-Menue-Reiter.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Settings.values.clear()
	Settings.load_file()
	check(Settings.get_value("window") == 1 and Settings.value_text("scale") == "100 %", "Standard: Vollbild, 100 %")
	check(Settings.preset_name() == "Eigene" or Settings.preset_name() == "Hoch", "Voreinstellung ist erkennbar")
	Settings.apply_preset("Niedrig")
	check(Settings.preset_name() == "Niedrig" and Settings.get_value("shadows") == 1 and not Settings.glow_on() and not Settings.tilt_on(), "Niedrig")
	Settings.cycle_preset()
	check(Settings.preset_name() == "Mittel" and Settings.particle_factor() == 1.0, "naechste Voreinstellung: Mittel")
	Settings.cycle("aa")
	check(Settings.preset_name() == "Eigene", "Einzelwert geaendert: Eigene")
	for i in 8:
		Settings.cycle("fps")
	check(Settings.get_value("fps") == 3 or Settings.get_value("fps") < 4, "Werte bleiben im Bereich")
	Settings.set_value("shadows", 99)
	check(Settings.get_value("shadows") == 3, "Wert wird begrenzt")
	# Speichern und Laden
	Settings.set_value("scale", 1)
	Settings.set_value("particles", 2)
	Settings.save_file()
	Settings.values.clear()
	Settings.load_file()
	check(Settings.get_value("scale") == 1 and Settings.get_value("particles") == 2, "gespeicherte Werte kommen zurueck")
	# Zuruecksetzen fuer andere Laeufe
	Settings.values.clear()
	Settings.save_file()
	# Pause-Menue
	var m := PauseMenu.new()
	m.can_save = false
	root.add_child(m)
	await process_frame
	var btns := m.find_children("*", "Button", true, false)
	var graf: Button
	for b: Button in btns:
		if b.text == "Grafik":
			graf = b
	check(graf != null, "Knopf Grafik im Pause-Menue")
	graf.pressed.emit()
	await process_frame
	var texts := m.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)
	check(texts.has("Schatten: Hoch") and texts.has("Anzeige: Vollbild"), "Grafik-Reiter zeigt Optionen: %s" % [texts])
	print("settings: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
