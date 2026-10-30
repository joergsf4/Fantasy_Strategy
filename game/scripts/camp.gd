class_name Camp
extends Control
## Lager zwischen Kapiteln: Haendler, Brauen, Ausruestung, Aufstellung. Aenderungen gehen direkt in den Party-Zustand.

signal closed

const TABS := ["Händler", "Brauen", "Ausrüstung", "Aufstellung"]
const SLOTS := {"waffe": "Waffe", "ruestung": "Rüstung", "talisman": "Talisman"}
const GOLD_COL := Color(1.0, 0.83, 0.42)

var party: Party
var unit_defs: Dictionary
var squad: Array = []
var _tab := 0
var _hero := ""
var _slot := ""
var _quip := ""
var _head: RichTextLabel
var _body: Control
var _tab_buttons: Array[Button] = []


func setup(p: Party, defs: Dictionary, squad_ids: Array) -> void:
	party = p
	unit_defs = defs
	squad = squad_ids
	_hero = squad_ids[0] if not squad_ids.is_empty() else ""
	_quip = (Party.shop_data()["quips"] as Array)[0]


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(28, 18, 28, 18), 0.95))
	panel.position = Vector2(110, 40)
	panel.custom_minimum_size = Vector2(1060, 640)
	panel.size = Vector2(1060, 640)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var title := _label("Lager", UiTheme.F_TITLE, 36, GOLD_COL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	col.add_child(tabs)
	for i in TABS.size():
		var b := _button(TABS[i], func() -> void:
			_tab = i
			_slot = ""
			_refresh(), Vector2(190, 36))
		tabs.add_child(b)
		_tab_buttons.append(b)
	_head = RichTextLabel.new()
	_head.bbcode_enabled = true
	_head.fit_content = true
	_head.scroll_active = false
	_head.add_theme_font_size_override("normal_font_size", 20)
	col.add_child(_head)
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)
	var go := _button("Weiter zum nächsten Kapitel", func() -> void:
		closed.emit()
		queue_free(), Vector2(320, 40))
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(go)
	_refresh()


# ------------------------------------------------------------------ Bausteine

func _label(text: String, font: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


## Textzeile; mit width > 0 bricht sie um (feste Breite, sonst kollabiert ein umbrechendes Label).
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


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


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


func _refresh() -> void:
	for i in _tab_buttons.size():
		_tab_buttons[i].disabled = i == _tab
	var mats: PackedStringArray = []
	for id: String in party.materials:
		if int(party.materials[id]) > 0:
			mats.append("%s ×%d" % [Items.item_name(id), int(party.materials[id])])
	var inv: PackedStringArray = []
	for id: String in party.inventory:
		if int(party.inventory[id]) > 0:
			inv.append("%s ×%d" % [Items.item_name(id), int(party.inventory[id])])
	_head.text = "[color=#ffd36b]Gold[/color] %d     [color=#ffd36b]Rucksack[/color] %s     [color=#ffd36b]Zutaten[/color] %s" % [
		party.gold, ", ".join(inv) if not inv.is_empty() else "leer", ", ".join(mats) if not mats.is_empty() else "keine"]
	_clear(_body)
	match _tab:
		0:
			_build_shop()
		1:
			_build_brew()
		2:
			_build_gear()
		3:
			_build_squad()


# ------------------------------------------------------------------ Haendler

func _build_shop() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	_body.add_child(row)
	var left := VBoxContainer.new()
	left.add_child(_portrait("haendler", Vector2(250, 290)))
	var nm := _label(Party.shop_data()["merchant"]["name"] + " (Händler)", UiTheme.F_HEAD, 20, GOLD_COL)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(nm)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 5)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(_text("„%s“" % _quip, 20, Color(0.9, 0.95, 0.8), 640))
	for w: Dictionary in party.stock():
		var id: String = w["id"]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item: Dictionary = Items.consumables().get(id, Items.equipment().get(id, {}))
		info.add_child(_text("%s  –  %s" % [item["name"], item.get("text", "")], 19, UiTheme.CREAM, 420))
		line.add_child(info)
		var price := _text("%d Gold" % w["price"], 19, GOLD_COL)
		price.custom_minimum_size = Vector2(80, 0)
		line.add_child(price)
		var buy := _button("Kaufen (%d übrig)" % w["left"] if w["left"] > 0 else "Ausverkauft", func() -> void:
			if party.buy(id):
				_quip = (Party.shop_data()["quips"] as Array)[randi() % Party.shop_data()["quips"].size()]
			_refresh(), Vector2(190, 30))
		buy.disabled = not party.can_buy(id)
		line.add_child(buy)
		right.add_child(line)


# ------------------------------------------------------------------ Brauen

func _build_brew() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_body.add_child(col)
	col.add_child(_text("Aus Zutaten werden im Lager feste Rezepte. Kein Zufall, kein Grinden.", 20, Color(0.8, 0.85, 0.75), 900))
	var recs := Party.recipes()
	for id: String in recs:
		var r: Dictionary = recs[id]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		line.add_child(_portrait(_crafter_portrait(r["crafter"]), Vector2(64, 76)))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost: PackedStringArray = []
		for m: String in r["cost"]:
			cost.append("%d %s (%d)" % [r["cost"][m], Items.item_name(m), int(party.materials.get(m, 0))])
		var crafter_name: String = unit_defs[r["crafter"]]["name"]
		info.add_child(_text("%s – %s" % [Items.item_name(id), Items.consumables()[id]["text"]], 20, UiTheme.CREAM, 620))
		info.add_child(_text("%s braut aus: %s" % [crafter_name, ", ".join(cost)], 17, Color(0.8, 0.8, 0.75), 620))
		info.add_child(_text(r["line"], 17, Color(0.85, 0.95, 0.8), 620))
		line.add_child(info)
		var b := _button("Herstellen", func() -> void:
			party.brew(id)
			_refresh(), Vector2(150, 34))
		b.disabled = not party.can_brew(id) or not squad.has(r["crafter"])
		line.add_child(b)
		col.add_child(line)


func _crafter_portrait(id: String) -> String:
	return id


# ------------------------------------------------------------------ Ausruestung

func _effective(hero: String) -> String:
	var d: Dictionary = unit_defs[hero]
	var u := {"atk": d["atk"], "def": d["def"], "res": d.get("res", 0), "hp": d["hp"], "maxhp": d["hp"], "move": d["move"],
		"range": d["range"], "dmg_type": d.get("dmg_type", "body")}
	Items.apply_equipment(u, party.equipment.get(hero, []))
	return "Leben %d   Angriff %d   Vert %d   Res %d   Bew %d   Reichweite %d" % [u["maxhp"], u["atk"], u["def"], u["res"], u["move"], u["range"]]


func _build_gear() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_body.add_child(row)
	var heroes := VBoxContainer.new()
	heroes.add_theme_constant_override("separation", 4)
	for id: String in squad:
		var b := _button(unit_defs[id]["name"], func() -> void:
			_hero = id
			_slot = ""
			_refresh(), Vector2(200, 34))
		b.disabled = id == _hero
		heroes.add_child(b)
	row.add_child(heroes)
	row.add_child(_portrait(_hero, Vector2(180, 240)))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(_label(unit_defs[_hero]["name"], UiTheme.F_HEAD, 24, GOLD_COL))
	right.add_child(_text(_effective(_hero), 19, Color(0.9, 0.9, 0.8), 560))
	for slot: String in SLOTS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var sl := _text(SLOTS[slot] + ":", 20, GOLD_COL)
		sl.custom_minimum_size = Vector2(100, 0)
		line.add_child(sl)
		var cur := party.worn_in(_hero, slot)
		var label: String = (Items.item_name(cur) + "  (" + Items.equipment()[cur]["text"] + ")") if cur != "" else "– leer –"
		var b := _button(label if _slot != slot else "▼ " + label, func() -> void:
			_slot = "" if _slot == slot else slot
			_refresh(), Vector2(420, 32))
		line.add_child(b)
		right.add_child(line)
		if _slot == slot:
			right.add_child(_candidates(slot))


func _candidates(slot: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var d: Dictionary = unit_defs[_hero]
	var found := false
	if party.worn_in(_hero, slot) != "":
		box.add_child(_button("Ablegen", func() -> void:
			party.unequip(_hero, slot)
			_refresh(), Vector2(200, 28)))
	for id: String in party.pool:
		if Items.equipment()[id]["slot"] != slot:
			continue
		var ok := Items.can_equip({"dmg_type": d.get("dmg_type", "body"), "range": int(d.get("range", 1))}, id)
		var it: Dictionary = Items.equipment()[id]
		var b := _button("%s  (%s)%s" % [it["name"], it["text"], "" if ok else "  – nicht tragbar"], func() -> void:
			party.equip(_hero, id, d)
			_slot = ""
			_refresh(), Vector2(520, 28))
		b.disabled = not ok
		box.add_child(b)
		found = true
	if not found and party.worn_in(_hero, slot) == "":
		box.add_child(_text("Nichts im Lager für diesen Platz. Beim Händler oder in Truhen finden.", 17, Color(0.8, 0.75, 0.7), 520))
	return box


# ------------------------------------------------------------------ Aufstellung

func _build_squad() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_body.add_child(col)
	col.add_child(_text("Diese Helden ziehen ins nächste Kapitel. Weitere schließen sich an, sobald die Geschichte sie trifft.", 20, Color(0.8, 0.85, 0.75), 900))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 14)
	col.add_child(grid)
	for id: String in squad:
		var card := VBoxContainer.new()
		card.add_child(_portrait(id, Vector2(150, 190)))
		var nm := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 15, GOLD_COL)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(nm)
		var gear: PackedStringArray = []
		for w: String in party.equipment.get(id, []):
			gear.append(Items.item_name(w))
		var gt := _text(", ".join(gear) if not gear.is_empty() else "ohne Ausrüstung", 15, Color(0.85, 0.85, 0.8), 150)
		gt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(gt)
		grid.add_child(card)
