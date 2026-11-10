class_name Chronicle
extends Control
## Chronik (Hauptmenue, nach dem Durchspielen): jede Kampfmission erneut spielen und Medaillen sammeln.
## Je Mission gibt es eine Medaille fuer den Sieg, eine je Bonusziel und eine fuer den Sieg auf "Schwer" (Party.records).
## Gespielt wird mit einer Gruppe, die zur Mission passt (Party.for_chapter), nicht mit dem Endstand: so bleibt jede Mission fordernd.

signal chosen(cid: String)      # "" = zurueck zum Hauptmenue

const GOLD_COL := Color(1.0, 0.83, 0.42)
const DIM_COL := Color(0.78, 0.76, 0.68)
const OK_COL := Color(0.55, 0.9, 0.55)
const HARD_COL := Color(0.95, 0.45, 0.4)

var missions: Array = []          # [{id, title, briefing, objectives}]
var records: Dictionary = {}
var _sel := ""
var _list: VBoxContainer
var _detail: VBoxContainer
var _rows: Dictionary = {}


func setup(mission_list: Array, party_records: Dictionary, selected := "") -> void:
	missions = mission_list
	records = party_records
	_sel = selected if selected != "" else (str(missions[0]["id"]) if not missions.is_empty() else "")


## Medaillen einer Mission: [erreicht, moeglich].
static func medals(m: Dictionary, rec: Dictionary) -> Array:
	var total := 2 + (m.get("objectives", []) as Array).size()
	var got := 0
	if rec.get("won", false):
		got += 1
		for o: Dictionary in m.get("objectives", []):
			if (rec.get("goals", []) as Array).has(o["id"]):
				got += 1
		if rec.get("hard", false):
			got += 1
	return [got, total]


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var got := 0
	var total := 0
	for m: Dictionary in missions:
		var md := medals(m, records.get(m["id"], {}))
		got += int(md[0])
		total += int(md[1])
	var top := _panel(Vector2(16, 10), Vector2(1248, 56), Vector4(24, 8, 24, 8))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	top.add_child(bar)
	bar.add_child(_label("Chronik", UiTheme.F_TITLE, 30, GOLD_COL))
	var mid := _label("Jede Mission noch einmal spielen", UiTheme.F_HEAD, 17, UiTheme.CREAM)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(mid)
	bar.add_child(_label("Medaillen %d / %d" % [got, total], UiTheme.F_HEAD, 20, GOLD_COL))
	var left := _panel(Vector2(16, 74), Vector2(560, 632), Vector4(14, 14, 10, 14))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	var right := _panel(Vector2(584, 74), Vector2(680, 632), Vector4(24, 18, 24, 18))
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	right.add_child(_detail)
	for m: Dictionary in missions:
		var row := _row(m)
		_rows[m["id"]] = row
		_list.add_child(row)
	_show(_sel)


func _panel(pos: Vector2, size_px: Vector2, content: Vector4) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, content, 0.95))
	p.position = pos
	p.custom_minimum_size = size_px
	p.size = size_px
	p.clip_contents = true
	add_child(p)
	return p


func _label(text: String, font: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _text(text: String, size_px := 18, color := UiTheme.CREAM, width := 0) -> Label:
	var l := _label(text, UiTheme.F_BODY, size_px, color)
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
	return l


func _button(text: String, cb: Callable, min_size := Vector2(200, 38)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 17)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b


func _flat(bg: Color, border: Color, width := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(5)
	return sb


## Reihe runder Medaillen: gold = erreicht, dunkel = offen, die letzte (Sieg auf Schwer) ist rot.
func _medal_row(m: Dictionary, rec: Dictionary, size_px := 12) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var states: Array = [rec.get("won", false)]
	for o: Dictionary in m.get("objectives", []):
		states.append(rec.get("won", false) and (rec.get("goals", []) as Array).has(o["id"]))
	states.append(rec.get("won", false) and rec.get("hard", false))
	for i in states.size():
		var dot := Panel.new()
		var sb := StyleBoxFlat.new()
		var hard := i == states.size() - 1
		sb.bg_color = (HARD_COL if hard else GOLD_COL) if states[i] else Color(0.2, 0.2, 0.27)
		sb.border_color = Color(0.6, 0.3, 0.28) if hard else Color(0.55, 0.45, 0.25)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(size_px)
		dot.add_theme_stylebox_override("panel", sb)
		dot.custom_minimum_size = Vector2(size_px, size_px)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)
	return row


func _row(m: Dictionary) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(520, 40)
	b.add_theme_stylebox_override("normal", _flat(Color(0.09, 0.1, 0.17, 0.7), Color(0.55, 0.45, 0.25, 0.4)))
	b.add_theme_stylebox_override("hover", _flat(Color(0.16, 0.17, 0.28, 0.95), Color(1.0, 0.83, 0.42, 0.9)))
	b.add_theme_stylebox_override("pressed", _flat(Color(0.16, 0.17, 0.28, 0.95), Color(1.0, 0.83, 0.42, 0.9)))
	b.add_theme_stylebox_override("disabled", _flat(Color(0.2, 0.17, 0.1, 0.95), Color(1.0, 0.83, 0.42, 1.0), 2))
	b.pressed.connect(func() -> void: _show(m["id"]))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 10)
	line.position = Vector2(10, 4)
	line.size = Vector2(500, 32)
	b.add_child(line)
	var no := _label(str(m["id"]).substr(2), UiTheme.F_HEAD, 15, GOLD_COL)
	no.custom_minimum_size = Vector2(28, 0)
	no.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(no)
	var title := _text(str(m["title"]), 18)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(title)
	line.add_child(_medal_row(m, records.get(m["id"], {})))
	return b


func _reward_text(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(r.get("gold", 0)) > 0:
		parts.append("%d Gold" % int(r["gold"]))
	for id: String in r.get("items", {}):
		parts.append("%s ×%d" % [Items.item_name(id), int(r["items"][id])])
	return ", ".join(parts)


func _show(cid: String) -> void:
	_sel = cid
	for id: String in _rows:
		(_rows[id] as Button).disabled = id == cid
	for c in _detail.get_children():
		c.queue_free()
	var m: Dictionary = {}
	for x: Dictionary in missions:
		if x["id"] == cid:
			m = x
	if m.is_empty():
		_detail.add_child(_text("Noch keine Mission freigeschaltet.", 20))
		return
	var rec: Dictionary = records.get(cid, {})
	_detail.add_child(_label("Mission %s" % cid.substr(2), UiTheme.F_HEAD, 15, GOLD_COL))
	var title := _label(str(m["title"]), UiTheme.F_HEAD, 24, UiTheme.CREAM)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(630, 0)
	_detail.add_child(title)
	if str(m.get("briefing", "")) != "":
		_detail.add_child(_text(str(m["briefing"]), 17, Color(0.88, 0.86, 0.78), 630))
	_detail.add_child(_label("Medaillen", UiTheme.F_HEAD, 16, GOLD_COL))
	_detail.add_child(_goal_line(rec.get("won", false), "Mission gewonnen" + ("  (beste Rundenzahl: %d)" % int(rec["turns"]) if int(rec.get("turns", 0)) > 0 else ""), GOLD_COL))
	for o: Dictionary in m.get("objectives", []):
		_detail.add_child(_goal_line(rec.get("won", false) and (rec.get("goals", []) as Array).has(o["id"]), str(o["text"]), GOLD_COL))
	_detail.add_child(_goal_line(rec.get("won", false) and rec.get("hard", false), "Auf Schwierigkeit „Schwer“ gewonnen", HARD_COL))
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(gap)
	_detail.add_child(_text("Ihr spielt mit einer Gruppe, wie sie zu dieser Stelle der Geschichte passt (Ausrüstung und Talente von damals). Schwierigkeit jetzt: %s (Pause-Menü, „Ton und Spiel“)." % Settings.value_text("difficulty"), 15, DIM_COL, 630))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	_detail.add_child(buttons)
	buttons.add_child(_button("Mission spielen", func() -> void:
		chosen.emit(cid)
		queue_free(), Vector2(260, 42)))
	buttons.add_child(_button("Zum Hauptmenü", func() -> void:
		chosen.emit("")
		queue_free(), Vector2(220, 42)))


func _goal_line(done: bool, text: String, col: Color) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(18, 24)
	var dot := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col if done else Color(0.2, 0.2, 0.27)
	sb.border_color = Color(0.55, 0.45, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	dot.add_theme_stylebox_override("panel", sb)
	dot.custom_minimum_size = Vector2(14, 14)
	holder.add_child(dot)
	line.add_child(holder)
	line.add_child(_text(text, 18, UiTheme.CREAM if done else DIM_COL, 590))
	return line
