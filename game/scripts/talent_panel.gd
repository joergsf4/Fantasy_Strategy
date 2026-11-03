class_name TalentPanel
extends HBoxContainer
## Talentpunkte verteilen (Lager-Reiter und Aufstieg-Bildschirm): links die Helden, rechts je Feld Rang (●○), Minus, Plus und was der naechste Rang bringt.
## Nur die uebergebenen Helden werden gezeigt (die Mission-Gruppe).

signal changed

const GOLD := Color(1.0, 0.83, 0.42)

var party: Party
var unit_defs: Dictionary
var heroes: Array = []
var _hero := ""
var _abilities: Dictionary = {}


func setup(p: Party, defs: Dictionary, hero_ids: Array) -> void:
	party = p
	unit_defs = defs
	heroes = hero_ids
	_hero = heroes[0] if not heroes.is_empty() else ""
	_abilities = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	rebuild()


func select(id: String) -> void:
	_hero = id
	rebuild()


func _label(text: String, font: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _text(text: String, size := 20, color := UiTheme.CREAM, width := 0) -> Label:
	var l := _label(text, UiTheme.F_BODY, size, color)
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
	return l


func _button(text: String, cb: Callable, min_size := Vector2(150, 32)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 16)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b


func _portrait(id: String, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var path := "res://assets/portraits/%s.png" % id
	if not ResourceLoader.exists(path):
		path = "res://assets/tokens/%s.png" % id
	t.texture = load(path)
	t.custom_minimum_size = size
	return t


func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if _hero == "":
		add_child(_text("Keine Helden in der Gruppe.", 20))
		return
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 3)
	for id: String in heroes:
		var b := _button("%s (%d)" % [unit_defs[id]["name"], party.points(id)], func() -> void: select(id), Vector2(200, 30))
		b.disabled = id == _hero
		list.add_child(b)
	add_child(list)
	add_child(_portrait(_hero, Vector2(170, 230)))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 7)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(right)
	var d: Dictionary = unit_defs[_hero]
	right.add_child(_label("%s   –   freie Talentpunkte: %d" % [d["name"], party.points(_hero)], UiTheme.F_HEAD, 22, GOLD))
	right.add_child(_text("Einen Punkt gibt es alle %d Stufen, aber nur für Helden, die in der Gruppe sind. Punkte lassen sich zurückholen und neu verteilen." % int(Talents.cfg()["levels_per_point"]), 16, Color(0.8, 0.85, 0.75), 520))
	var rk := party.ranks(_hero)
	var rows := [["hp", "Leben", "+%d Leben je Rang" % int(Talents.cfg()["hp_per_rank"])], ["atk", "Angriff", "+%d Angriff je Rang" % int(Talents.cfg()["atk_per_rank"])]]
	for key in ["a1", "a2"]:
		var aid := Talents.ability_of(d, key)
		if aid != "" and _abilities.has(aid):
			rows.append([key, "Fähigkeit: " + str(_abilities[aid]["name"]), Talents.next_rank_text(_abilities[aid], int(rk[key]))])
	for r: Array in rows:
		var key: String = r[0]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var nm := _text(str(r[1]), 19, UiTheme.CREAM, 250)
		nm.custom_minimum_size = Vector2(250, 0)
		line.add_child(nm)
		var pips := ""
		for i in Talents.max_rank():
			pips += "● " if i < int(rk[key]) else "○ "
		var pl := _text(pips, 22, GOLD)
		pl.custom_minimum_size = Vector2(90, 0)
		line.add_child(pl)
		var minus := _button("−", func() -> void:
			party.refund_point(_hero, key)
			rebuild()
			changed.emit(), Vector2(40, 30))
		minus.disabled = int(rk[key]) <= 0
		line.add_child(minus)
		var plus := _button("+", func() -> void:
			party.spend_point(_hero, key)
			rebuild()
			changed.emit(), Vector2(40, 30))
		plus.disabled = party.points(_hero) <= 0 or int(rk[key]) >= Talents.max_rank()
		line.add_child(plus)
		right.add_child(line)
		var eff := ""
		if key in ["a1", "a2"]:
			eff = ("Nächster Rang: " + str(r[2])) if int(rk[key]) < Talents.max_rank() else "Höchster Rang"
		else:
			eff = str(r[2])
		right.add_child(_text(eff, 16, Color(0.75, 0.85, 0.95), 560))
	right.add_child(_text(_effective(_hero), 17, Color(0.85, 0.9, 0.75), 600))


func _effective(hero: String) -> String:
	var d: Dictionary = unit_defs[hero]
	var tl := party.ranks(hero)
	var u := {"atk": d["atk"] + Talents.atk_bonus(tl), "def": d["def"], "res": d.get("res", 0), "hp": d["hp"] + Talents.hp_bonus(tl), "maxhp": d["hp"] + Talents.hp_bonus(tl),
		"move": d["move"], "range": d["range"], "dmg_type": d.get("dmg_type", "body")}
	Items.apply_equipment(u, party.equipment.get(hero, []))
	return "Leben %d   Angriff %d   Vert %d   Res %d   Bew %d   Reichweite %d" % [u["maxhp"], u["atk"], u["def"], u["res"], u["move"], u["range"]]
