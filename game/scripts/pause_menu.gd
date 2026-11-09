class_name PauseMenu
extends Control
## Menue mit Esc: Weiter, Speichern, Vollbild, Beenden. Haelt das Spiel an (Szenenbaum pausiert) und laeuft selbst weiter.
## Gespeichert wird der Stand nach der letzten geschafften Mission (Gold, Rucksack, Ausruestung, Gruppe); die laufende Mission beginnt nach dem Laden von vorn.

signal closed
signal save_requested
signal quit_requested
signal menu_requested
signal restart_requested
signal fullscreen_toggled

var can_restart := false        # nur waehrend eines Kampfes: Mission neu starten
var can_save := true            # im Hauptmenue gibt es noch nichts zu speichern
var _panel: PanelContainer
var _col: VBoxContainer
var _msg: Label
var _fs_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiTheme.get_theme()
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.62)
	dim.size = Vector2(1280, 720)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(40, 28, 40, 28), 0.96))
	_panel.position = Vector2(440, 150)
	_panel.custom_minimum_size = Vector2(400, 0)
	add_child(_panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	_panel.add_child(_col)
	_show_main()
	get_tree().paused = true


func _label(text: String, font: String, size: int, color: Color, wrap := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	if wrap > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap, 0)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 42)
	b.add_theme_font_size_override("font_size", 20)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b


func _clear() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()


func _show_main() -> void:
	_panel.position = Vector2(440, 150)
	_clear()
	_col.add_child(_label("Pause", UiTheme.F_TITLE, 40, UiTheme.GOLD))
	_panel.reset_size.call_deferred()
	var first := _button("Weiter", close)
	_col.add_child(first)
	var save := _button("Speichern", _on_save)
	save.disabled = not can_save
	_col.add_child(save)
	_fs_button = _button(_fullscreen_text(), func() -> void:
		fullscreen_toggled.emit()
		_fs_button.text = _fullscreen_text())
	_col.add_child(_fs_button)
	_col.add_child(_button("Grafik", _show_graphics))
	_col.add_child(_button("Ton und Spiel", _show_sound))
	if can_restart:
		_col.add_child(_button("Mission neu starten", _confirm_restart))
	if can_save:      # im Hauptmenue selbst gibt es keinen Weg dorthin zurueck
		_col.add_child(_button("Zum Hauptmenü", _confirm_menu))
	_col.add_child(_button("Beenden", _confirm_quit))
	_msg = _label("", UiTheme.F_BODY, 17, Color(0.7, 1.0, 0.7), 340)
	_col.add_child(_msg)
	first.grab_focus.call_deferred()


func _fullscreen_text() -> String:
	var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	return "Vollbild: " + ("an" if fs else "aus")


func _on_save() -> void:
	save_requested.emit()
	_msg.text = "Gespeichert. Gesichert ist der Stand nach der letzten geschafften Mission; die laufende beginnt nach dem Laden von vorn."


func _confirm_quit() -> void:
	_clear()
	_col.add_child(_label("Spiel beenden?", UiTheme.F_TITLE, 32, UiTheme.GOLD))
	var txt := "Gespeichert ist der Stand nach der letzten geschafften Mission. Die laufende Mission beginnt beim nächsten Start von vorn." if can_save else "Das Spiel wird geschlossen."
	_col.add_child(_label(txt, UiTheme.F_BODY, 19, UiTheme.CREAM, 340))
	var yes := _button("Ja, beenden", func() -> void: quit_requested.emit())
	_col.add_child(yes)
	var back := _button("Zurück", _show_main)
	_col.add_child(back)
	back.grab_focus.call_deferred()


## Reiter "Ton und Spiel": Lautstaerke von Musik und Effekten, Schwierigkeit (gilt ab dem naechsten Kampf). Wirkt sofort, wird gespeichert.
func _show_sound() -> void:
	_panel.position = Vector2(440, 150)
	_clear()
	_col.add_child(_label("Ton und Spiel", UiTheme.F_TITLE, 36, UiTheme.GOLD))
	_panel.reset_size.call_deferred()      # Panel auf den (kuerzeren) Inhalt schrumpfen
	var buttons: Dictionary = {}
	var refresh := func() -> void:
		for o: Dictionary in Settings.OPTIONS:
			if buttons.has(o["key"]):
				(buttons[o["key"]] as Button).text = "%s: %s" % [o["label"], Settings.value_text(o["key"])]
	for o: Dictionary in Settings.OPTIONS:
		if o.get("tab", "") != "ton":
			continue
		var key: String = o["key"]
		var b := _button("", func() -> void:
			Settings.cycle(key)
			Settings.apply_audio()
			Settings.save_file()
			if key == "sfx":
				Sfx.event("coin")      # Probeklang in der neuen Lautstaerke
			refresh.call())
		buttons[key] = b
		_col.add_child(b)
	refresh.call()
	_col.add_child(_label("Die Schwierigkeit gilt ab dem nächsten Kampf.", UiTheme.F_BODY, 17, Color(0.8, 0.8, 0.75), 340))
	var back := _button("Zurück", _show_main)
	_col.add_child(back)
	back.grab_focus.call_deferred()


## Reiter "Grafik": jede Option ist ein Knopf, der beim Klicken den naechsten Wert waehlt (Settings.OPTIONS); wirkt sofort und wird gespeichert.
func _show_graphics() -> void:
	_panel.position = Vector2(440, 14)
	_clear()
	_col.add_theme_constant_override("separation", 5)
	_col.add_child(_label("Grafik", UiTheme.F_TITLE, 36, UiTheme.GOLD))
	var buttons: Dictionary = {}
	var refresh := func() -> void:
		for o: Dictionary in Settings.OPTIONS:
			if buttons.has(o["key"]):
				(buttons[o["key"]] as Button).text = "%s: %s" % [o["label"], Settings.value_text(o["key"])]
		(buttons["_preset"] as Button).text = "Voreinstellung: " + Settings.preset_name()
	var preset := _button("", func() -> void:
		Settings.cycle_preset()
		Settings.apply()
		Settings.save_file()
		refresh.call())
	preset.custom_minimum_size = Vector2(320, 35)
	buttons["_preset"] = preset
	_col.add_child(preset)
	for o: Dictionary in Settings.OPTIONS:
		if o.get("tab", "") == "ton":
			continue
		var key: String = o["key"]
		var b := _button("", func() -> void:
			Settings.cycle(key)
			Settings.apply()
			Settings.save_file()
			refresh.call())
		b.custom_minimum_size = Vector2(320, 35)
		buttons[key] = b
		_col.add_child(b)
	refresh.call()
	var back := _button("Zurück", func() -> void:
		_col.add_theme_constant_override("separation", 10)
		_show_main())
	back.custom_minimum_size = Vector2(320, 35)
	_col.add_child(back)
	back.grab_focus.call_deferred()


func _confirm_restart() -> void:
	_clear()
	_col.add_child(_label("Mission neu starten?", UiTheme.F_TITLE, 32, UiTheme.GOLD))
	_col.add_child(_label("Der Kampf beginnt von vorn, der Fortschritt dieser Mission geht verloren (nichts wird gespeichert).", UiTheme.F_BODY, 19, UiTheme.CREAM, 340))
	_col.add_child(_button("Ja, neu starten", func() -> void: restart_requested.emit()))
	var back := _button("Zurück", _show_main)
	_col.add_child(back)
	back.grab_focus.call_deferred()


func _confirm_menu() -> void:
	_clear()
	_col.add_child(_label("Zum Hauptmenü?", UiTheme.F_TITLE, 32, UiTheme.GOLD))
	_col.add_child(_label("Gespeichert ist der Stand nach der letzten geschafften Mission. Die laufende Mission beginnt beim Fortfahren von vorn.", UiTheme.F_BODY, 19, UiTheme.CREAM, 340))
	_col.add_child(_button("Ja, zum Hauptmenü", func() -> void: menu_requested.emit()))
	var back := _button("Zurück", _show_main)
	_col.add_child(back)
	back.grab_focus.call_deferred()


func close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()

