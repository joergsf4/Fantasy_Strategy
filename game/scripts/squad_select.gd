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
	for id: String in Party.roster(defs, int(String(m["id"]).substr(2))):
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
	panel.position = Vector2(90, 34)
	panel.custom_minimum_size = Vector2(1100, 650)
	panel.size = Vector2(1100, 650)
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
	_body.custom_minimum_size = Vector2(1040, 0)
	scroll.add_child(_body)
	var go := _button("Los geht's", func() -> void:
		closed.emit()
		queue_free(), Vector2(260, 42))
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(go)
	_refresh()


func _refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var fixed: Array = Mission.dialogue_ids(mission["id"])
	var hint := _text("Wer in diesem Kapitel spricht (🔒 Story), muss mit. Alle anderen Plätze lassen sich tauschen. Ausrüstung von Zurückbleibenden wandert ins Lager.", 19, Color(0.8, 0.85, 0.75), 1030)
	_body.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_body.add_child(row)
	for i in squad.size():
		var id: String = squad[i]
		var locked: bool = fixed.has(id)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		card.add_child(_portrait(id, Vector2(150, 150)))
		var nm := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 15, GOLD_COL)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(nm)
		var info := _text(_stats(id), 14, Color(0.85, 0.85, 0.8), 150)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(info)
		var b := _button("🔒 Story" if locked else ("▲ Auswahl" if _pick == i else "Tauschen"), func() -> void:
			_pick = -1 if _pick == i else i
			_refresh(), Vector2(150, 30))
		b.disabled = locked
		card.add_child(b)
		row.add_child(card)
	if _pick >= 0:
		_body.add_child(_label("Ersatz für %s:" % unit_defs[squad[_pick]]["name"], UiTheme.F_HEAD, 20, GOLD_COL))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 8)
		_body.add_child(flow)
		for id: String in Party.roster(unit_defs, int(String(mission["id"]).substr(2))):
			if squad.has(id):
				continue
			var cand := VBoxContainer.new()
			cand.add_theme_constant_override("separation", 1)
			cand.add_child(_portrait(id, Vector2(80, 80)))
			var cb := _button(unit_defs[id]["name"], func() -> void:
				if party.set_squad_member(mission, _pick, id):
					squad = party.squad_for(mission)
				_pick = -1
				_refresh(), Vector2(150, 28))
			cand.add_child(cb)
			var ci := _text(ROLES.get(unit_defs[id].get("role", ""), ""), 13, Color(0.82, 0.82, 0.78), 150)
			ci.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cand.add_child(ci)
			flow.add_child(cand)


func _stats(id: String) -> String:
	var d: Dictionary = unit_defs[id]
	return "%s · Leben %d · Angriff %d" % [ROLES.get(d.get("role", ""), ""), int(d["hp"]), int(d["atk"])]


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
