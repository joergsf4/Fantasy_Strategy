class_name PauseMenu
extends Control
## Menue mit Esc: Weiter, Speichern, Vollbild, Beenden. Haelt das Spiel an (Szenenbaum pausiert) und laeuft selbst weiter.
## Gespeichert wird der Stand nach der letzten geschafften Mission (Gold, Rucksack, Ausruestung, Gruppe); die laufende Mission beginnt nach dem Laden von vorn.

signal closed
signal save_requested
signal quit_requested
signal fullscreen_toggled

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
	_clear()
	_col.add_child(_label("Pause", UiTheme.F_TITLE, 40, UiTheme.GOLD))
	var first := _button("Weiter", close)
	_col.add_child(first)
	var save := _button("Speichern", _on_save)
	save.disabled = not can_save
	_col.add_child(save)
	_fs_button = _button(_fullscreen_text(), func() -> void:
		fullscreen_toggled.emit()
		_fs_button.text = _fullscreen_text())
	_col.add_child(_fs_button)
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


func close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()

