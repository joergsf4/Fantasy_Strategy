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
var secrets: Array = []       # [{id, name, heroes}]
var _sec: OptionButton
var _secret_foe := "soldat_infanterie"      # Gegner des gewaehlten Geheimnisses (z. B. Maja), sonst Buettel
var _sh: Array[OptionButton] = []     # drei Helden fuer die Geheimnis-Arena (der dritte ist optional)


func setup(hero_list: Array, foe_list: Array, secret_list: Array = []) -> void:
	heroes = hero_list
	foes = foe_list
	secrets = secret_list


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(34, 24, 34, 24), 0.97))
	var center := CenterContainer.new()      # mittig, egal wie breit die Spalten werden
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.size = get_viewport_rect().size
	add_child(center)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	outer.add_child(_label("Testlabor", UiTheme.F_TITLE, 32, UiTheme.GOLD))
	outer.add_child(_label("Direkt zu einer Stelle springen, ohne Missionen zu spielen", UiTheme.F_BODY, 16, Color(0.75, 0.8, 0.7)))
	var cols := HBoxContainer.new()      # zwei Spalten, damit alles auf den Bildschirm passt
	cols.add_theme_constant_override("separation", 34)
	outer.add_child(cols)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	cols.add_child(col)
	var col2 := VBoxContainer.new()
	col2.add_theme_constant_override("separation", 7)
	cols.add_child(col2)
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
	col.add_child(_label("Geheimnisse: Heldenkombination testen", UiTheme.F_HEAD, 20, UiTheme.CREAM))
	_sec = OptionButton.new()
	_sec.focus_mode = Control.FOCUS_NONE
	_sec.custom_minimum_size = Vector2(420, 34)
	_sec.add_theme_font_size_override("font_size", 19)
	_sec.add_item("Geheimnis wählen (setzt die Helden) …", 0)
	for i in secrets.size():
		var who: String = " + ".join(secrets[i]["heroes"].map(func(h: String) -> String: return _hero_name(h)))
		if str(secrets[i].get("foe_name", "")) != "":
			who = "%s gegen %s" % [_hero_name(secrets[i]["heroes"][0]), secrets[i]["foe_name"]]
		_sec.add_item("%s (%s)" % [secrets[i]["name"], who], i + 1)
	var pop := _sec.get_popup()      # Liste darf nie ueber den Bildschirm laufen: kleinere Schrift, hoechstens 330 Pixel hoch (dann scrollbar)
	pop.add_theme_font_size_override("font_size", 16)
	pop.max_size = Vector2i(900, 330)
	_sec.item_selected.connect(_pick_secret)
	col.add_child(_sec)
	for k in 3:
		var d := _drop(heroes if k < 2 else [{"id": "", "name": "– kein dritter Held –"}] + heroes)
		if k == 1 and heroes.size() > 1:
			d.select(1)
		_sh.append(d)
		col.add_child(d)
	col.add_child(_button("Geheimnis-Arena starten (Helden nebeneinander, 3 Büttel)", func() -> void:
		var ids: Array[String] = []
		for k in 3:
			var id: String = (heroes if k < 2 else [{"id": ""}] + heroes)[_sh[k].selected]["id"]
			if id != "" and not ids.has(id):
				ids.append(id)
		run.emit("geheimnis", ",".join(ids), _secret_foe, false)))
	col2.add_child(_label("Bildschirme", UiTheme.F_HEAD, 20, UiTheme.CREAM))
	col2.add_child(_button("Aufstiegsbildschirm (Stufe 4, ein Punkt)", func() -> void: run.emit("aufstieg", _hero_id(), _foe_id(), false)))
	col2.add_child(_button("Lager (Kapitel 8, 999 Gold)", func() -> void: run.emit("lager", _hero_id(), _foe_id(), false)))
	col2.add_child(_button("Belohnungs- und Statistikbildschirm", func() -> void: run.emit("belohnung", _hero_id(), _foe_id(), false)))
	col2.add_child(_button("Reisebild Kapitel 2 (Schiff)", func() -> void: run.emit("reise", _hero_id(), _foe_id(), false)))
	col2.add_child(_button("Zurück", func() -> void:
		closed.emit()
		queue_free()))


func _hero_name(id: String) -> String:
	for h: Dictionary in heroes:
		if h["id"] == id:
			return h["name"]
	return id


func _pick_secret(i: int) -> void:
	_secret_foe = "soldat_infanterie"
	if i <= 0:
		return
	var hs: Array = secrets[i - 1]["heroes"]
	_secret_foe = str(secrets[i - 1].get("foe", "soldat_infanterie"))
	for k in 2:
		for j in heroes.size():
			if heroes[j]["id"] == hs[k]:
				_sh[k].select(j)
	_sh[2].select(0)


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
