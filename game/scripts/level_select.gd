class_name LevelSelect
extends Control
## Kapitelwahl nach "Press Start" (zu Testzwecken): pro Kapitel mit Einleitung oder direkt in den Kampf.

signal chosen(index: int, skip_story: bool)

var chapters: Array = []     # [{id, title}]


func setup(list: Array) -> void:
	chapters = list


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(34, 24, 34, 24), 0.95))
	panel.position = Vector2(300, 150)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(_label("Kapitel wählen", UiTheme.F_TITLE, 36, UiTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(_label("Testmenü", UiTheme.F_BODY, 18, Color(0.75, 0.75, 0.7), HORIZONTAL_ALIGNMENT_CENTER))
	for i in chapters.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var nm := _label("%d  %s" % [i + 1, chapters[i]["title"]], UiTheme.F_HEAD, 22, UiTheme.CREAM)
		nm.custom_minimum_size = Vector2(300, 0)
		row.add_child(nm)
		row.add_child(_button("Mit Einleitung", func() -> void: pick(i, false)))
		row.add_child(_button("Direkt in den Kampf", func() -> void: pick(i, true)))
		col.add_child(row)
	col.add_child(_button("Soundlabor", _open_lab))


func _open_lab() -> void:
	add_child(SoundLab.new())


func pick(index: int, skip_story: bool) -> void:
	chosen.emit(index, skip_story)
	queue_free()


func _label(text: String, font: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(190, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 16)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b
