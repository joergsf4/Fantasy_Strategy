class_name LevelSelect
extends Control
## Kapitelwahl nach "Press Start" (zu Testzwecken): pro Kapitel mit Einleitung oder direkt in den Kampf.

signal chosen(index: int, skip_story: bool)
signal new_game_requested
signal finale_end_requested      # Testmenue: Finale direkt am Ende des Kampfs gegen den Sack (bis zum Abspann ansehen)

var lab_runner := Callable()      # Main: func(kind, hero, foe, maxed) -> Coroutine (Testlabor)
var lab_heroes: Array = []
var lab_foes: Array = []
var lab_secrets: Array = []      # [{id, name, heroes: [id, id]}]

var chapters: Array = []     # [{id, title}]
var save_info := ""
var _info: Label


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
	_info = _label(save_info, UiTheme.F_BODY, 16, Color(0.8, 0.85, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_info)
	var dd := OptionButton.new()
	dd.focus_mode = Control.FOCUS_NONE
	dd.custom_minimum_size = Vector2(420, 40)
	dd.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	dd.add_theme_font_size_override("font_size", 22)
	for i in chapters.size():
		dd.add_item("%d  %s" % [i + 1, chapters[i]["title"]], i)
	dd.select(chapters.size() - 1)          # zuletzt gebautes Kapitel vorgewaehlt
	col.add_child(dd)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_button("Mit Einleitung", func() -> void: pick(dd.selected, false)))
	row.add_child(_button("Direkt in den Kampf", func() -> void: pick(dd.selected, true)))
	col.add_child(row)
	var fin := chapters.map(func(c: Dictionary) -> String: return c["id"]).find("ch25")
	if fin >= 0:
		col.add_child(_button("Finale: Sieg über den Sack (bis zum Schluss)", func() -> void:
			finale_end_requested.emit()
			pick(fin, true)))
	col.add_child(_button("Soundlabor", _open_lab))
	col.add_child(_button("Testlabor (Arena, Bildschirme, Lager)", _open_test_lab))
	col.add_child(_button("Spielstand zurücksetzen", func() -> void: new_game_requested.emit()))


func refresh_info() -> void:
	if _info != null:
		_info.text = save_info


func _open_test_lab() -> void:
	var tl := TestLab.new()
	tl.setup(lab_heroes, lab_foes, lab_secrets)
	tl.run.connect(func(kind: String, hero: String, foe: String, maxed: bool) -> void:
		visible = false
		await lab_runner.call(kind, hero, foe, maxed)
		visible = true)
	add_child(tl)


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
