class_name SquadSelect
extends Control
## Gruppenwahl vor der Runde (nach der Einleitung, vor dem Kampf): Die Plaetze der Karte, wer im Kapitel spricht ist gesperrt (🔒 Story),
## alle anderen Plaetze lassen sich mit den uebrigen freigeschalteten Helden tauschen. Aenderungen gehen direkt in den Party-Zustand.

signal closed

const GOLD_COL := Color(1.0, 0.83, 0.42)
const ROLES := {"tank": "Tank", "damage": "Angriff", "healer": "Heiler", "ranged": "Fernkampf", "mage": "Magier", "melee": "Nahkampf", "support": "Unterstützung"}

var party: Party
var unit_defs: Dictionary
var mission: Dictionary = {}
var squad: Array = []
var _pick := -1
var _body: VBoxContainer


func setup(p: Party, defs: Dictionary, m: Dictionary) -> void:
	party = p
	unit_defs = defs
	mission = m
	squad = party.squad_for(m)


## Gibt es hier ueberhaupt etwas zu waehlen? (ein freier Platz und ein verfuegbarer Ersatz)
static func has_choice(p: Party, defs: Dictionary, m: Dictionary) -> bool:
	var squad_ids := p.squad_for(m)
	var fixed: Array = Mission.dialogue_ids(m["id"])
	var free_slot := false
	for id: String in squad_ids:
		if not fixed.has(id):
			free_slot = true
	if not free_slot:
		return false
	for id: String in Party.roster(defs, int(String(m["id"]).substr(2)), true, p.recruited):
		if not squad_ids.has(id):
			return true
	return false


func _ready() -> void:
	theme = UiTheme.get_theme()
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.size = Vector2(1280, 720)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(28, 18, 28, 18), 0.95))
	panel.position = Vector2(50, 30)
	panel.custom_minimum_size = Vector2(1180, 660)
	panel.size = Vector2(1180, 660)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var title := _label("Gruppenwahl", UiTheme.F_TITLE, 36, GOLD_COL)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := _label(str(mission.get("title", "")), UiTheme.F_HEAD, 22, UiTheme.CREAM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var scroll := ScrollContainer.new()          # falls viele Ersatzhelden zur Wahl stehen
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_body.custom_minimum_size = Vector2(1120, 0)
	scroll.add_child(_body)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 30)
	col.add_child(bottom)
	var auto := CheckButton.new()      # Option: freie Ausruestungsplaetze der Gruppe vor der Mission aus dem Lager fuellen
	auto.text = "Ausrüstung automatisch verteilen"
	auto.button_pressed = party.auto_gear
	auto.focus_mode = Control.FOCUS_NONE
	auto.add_theme_font_override("font", UiTheme.font(UiTheme.F_BODY))
	auto.add_theme_font_size_override("font_size", 20)
	auto.add_theme_color_override("font_color", UiTheme.CREAM)
	auto.toggled.connect(func(on: bool) -> void: party.auto_gear = on)
	bottom.add_child(auto)
	var go := _button("Los geht's", func() -> void:
		closed.emit()
		queue_free(), Vector2(260, 42))
	bottom.add_child(go)
	_refresh()


## Aufbau (ohne Scrollen): oben die Truppe als kompakte Karten, darunter immer sichtbar die Reservebank als dichtes Raster. Erst auf "Tauschen" bei einem
## Platz, dann auf einen Helden der Bank klicken: ein Klick, zwei Schritte. Gewaehlter Platz ist hervorgehoben, die Bank zeigt, wer ersetzt wird.
func _refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var fixed: Array = Mission.dialogue_ids(mission["id"])
	_body.add_child(_text("🔒 Story: muss mit. Alle anderen Plätze lassen sich tauschen. Ausrüstung von Zurückbleibenden wandert ins Lager, Neue bekommen auf Wunsch (unten) freie Stücke daraus.", 16, Color(0.8, 0.85, 0.75), 1120))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(row)
	for i in squad.size():
		var id: String = squad[i]
		var locked: bool = fixed.has(id)
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.25, 0.2, 0.08, 0.7) if _pick == i else Color(0.1, 0.12, 0.2, 0.55)
		sb.border_color = GOLD_COL if _pick == i else Color(0.4, 0.42, 0.5, 0.6)
		sb.set_border_width_all(2 if _pick == i else 1)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(5)
		card.add_theme_stylebox_override("panel", sb)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 1)
		card.add_child(cv)
		cv.add_child(_portrait(id, Vector2(124, 100)))
		var nm := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 13, GOLD_COL)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size = Vector2(124, 32)
		cv.add_child(nm)
		var info := _text(_stats(id), 12, Color(0.85, 0.85, 0.8), 124)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(info)
		var b := _button("🔒 Story" if locked else ("▲ gewählt" if _pick == i else "Tauschen"), func() -> void:
			_pick = -1 if _pick == i else i
			_refresh(), Vector2(124, 26))
		b.disabled = locked
		cv.add_child(b)
		row.add_child(card)
	var bench: Array = []
	for id: String in Party.roster(unit_defs, int(String(mission["id"]).substr(2)), true, party.recruited):
		if not squad.has(id):
			bench.append(id)
	var head := "Reservebank (%d)" % bench.size()
	if _pick >= 0:
		head = "Wer ersetzt %s? Klicke auf einen Helden:" % unit_defs[squad[_pick]]["name"]
	elif not bench.is_empty():
		head += "  –  zuerst oben bei einem Platz auf „Tauschen“ klicken"
	_body.add_child(_label(head, UiTheme.F_HEAD, 18, GOLD_COL if _pick >= 0 else Color(0.8, 0.85, 0.75)))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 6)
	flow.custom_minimum_size = Vector2(1120, 0)
	_body.add_child(flow)
	for id: String in bench:
		var cb := Button.new()                 # die ganze Karte ist der Knopf (Portrait, Name, Rolle)
		cb.focus_mode = Control.FOCUS_NONE
		cb.custom_minimum_size = Vector2(110, 124)
		cb.disabled = _pick < 0
		cb.tooltip_text = _stats(id)
		for st in ["normal", "hover", "pressed", "disabled"]:
			cb.add_theme_stylebox_override(st, UiTheme.soft_button(st))
		cb.pressed.connect(func() -> void:
			if party.set_squad_member(mission, _pick, id):
				squad = party.squad_for(mission)
			_pick = -1
			_refresh())
		var cand := VBoxContainer.new()
		cand.add_theme_constant_override("separation", 0)
		cand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cand.set_anchors_preset(Control.PRESET_FULL_RECT)
		cb.add_child(cand)
		var pt := _portrait(id, Vector2(110, 58))
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pt.modulate = Color.WHITE if _pick >= 0 else Color(0.75, 0.75, 0.75)
		cand.add_child(pt)
		var nl := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 12, GOLD_COL if _pick >= 0 else Color(0.7, 0.7, 0.65))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(106, 34)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cand.add_child(nl)
		var ci := _label(ROLES.get(unit_defs[id].get("role", ""), ""), UiTheme.F_BODY, 12, Color(0.82, 0.82, 0.78))
		ci.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cand.add_child(ci)
		flow.add_child(cb)


func _stats(id: String) -> String:
	var d: Dictionary = unit_defs[id]
	return "%s · L %d · A %d" % [ROLES.get(d.get("role", ""), ""), int(d["hp"]), int(d["atk"])]


func _label(text: String, font: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _text(text: String, size: int, color: Color, width: int) -> Label:
	var l := _label(text, UiTheme.F_BODY, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


func _button(text: String, cb: Callable, min_size: Vector2) -> Button:
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
