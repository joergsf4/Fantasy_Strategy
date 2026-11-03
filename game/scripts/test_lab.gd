class_name TestLab
extends Control
## Testlabor (im Kapitelmenue nach "brumm"): springt direkt zu einer Stelle, an der man eine Aenderung sehen kann, ohne Missionen zu spielen.
## Arena (Held gegen Gegner, optional mit vollen Talenten und Ausruestung), Aufstiegsbildschirm, Lager, Belohnungsbildschirm, Reisebild.

signal run(kind: String, hero: String, foe: String, maxed: bool)
signal closed

var heroes: Array = []        # [{id, name}]
var foes: Array = []          # [{id, name}]
var _hero: OptionButton
var _foe: OptionButton
var _maxed: CheckBox


func setup(hero_list: Array, foe_list: Array) -> void:
	heroes = hero_list
	foes = foe_list


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(34, 24, 34, 24), 0.97))
	panel.position = Vector2(330, 90)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	panel.add_child(col)
	col.add_child(_label("Testlabor", UiTheme.F_TITLE, 34, UiTheme.GOLD))
	col.add_child(_label("Direkt zu einer Stelle springen, ohne Missionen zu spielen", UiTheme.F_BODY, 17, Color(0.75, 0.8, 0.7)))
	col.add_child(_label("Arena: Held gegen Gegner", UiTheme.F_HEAD, 20, UiTheme.CREAM))
	_hero = _drop(heroes)
	col.add_child(_hero)
	_foe = _drop(foes)
	col.add_child(_foe)
	_maxed = CheckBox.new()
	_maxed.text = "Volle Talente und Ausrüstung Stufe 3"
	_maxed.add_theme_font_size_override("font_size", 17)
	col.add_child(_maxed)
	col.add_child(_button("Arena starten", func() -> void: run.emit("arena", _hero_id(), _foe_id(), _maxed.button_pressed)))
	col.add_child(_label("Bildschirme", UiTheme.F_HEAD, 20, UiTheme.CREAM))
	col.add_child(_button("Aufstiegsbildschirm (Stufe 4, ein Punkt)", func() -> void: run.emit("aufstieg", _hero_id(), _foe_id(), false)))
	col.add_child(_button("Lager (Kapitel 8, 999 Gold)", func() -> void: run.emit("lager", _hero_id(), _foe_id(), false)))
	col.add_child(_button("Belohnungs- und Statistikbildschirm", func() -> void: run.emit("belohnung", _hero_id(), _foe_id(), false)))
	col.add_child(_button("Reisebild Kapitel 2 (Schiff)", func() -> void: run.emit("reise", _hero_id(), _foe_id(), false)))
	col.add_child(_button("Zurück", func() -> void:
		closed.emit()
		queue_free()))


func _hero_id() -> String:
	return heroes[_hero.selected]["id"]


func _foe_id() -> String:
	return foes[_foe.selected]["id"]


func _drop(list: Array) -> OptionButton:
	var d := OptionButton.new()
	d.focus_mode = Control.FOCUS_NONE
	d.custom_minimum_size = Vector2(420, 34)
	d.add_theme_font_size_override("font_size", 19)
	for i in list.size():
		d.add_item(str(list[i]["name"]), i)
	return d


func _label(text: String, font: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(420, 34)
	b.add_theme_font_size_override("font_size", 17)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b
