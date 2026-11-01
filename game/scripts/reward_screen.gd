class_name RewardScreen
extends Control
## Belohnungsbildschirm nach einem gewonnenen Kampf: Beute, Gold, Bonusziele, Statistik. "Weiter" schliesst ihn.
## Nach einer Niederlage (results["defeat"]) zeigt er nur die Statistik mit dem Knopf "Noch einmal versuchen".

signal closed

var results: Dictionary = {}


func setup(r: Dictionary) -> void:
	results = r


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(30, 22, 30, 22), 0.94))
	panel.custom_minimum_size = Vector2(560, 0)
	panel.position = Vector2(60, 90)
	add_child(panel)
	_build_stats()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var defeat: bool = results.get("defeat", false)
	col.add_child(_label("Niederlage …" if defeat else "Sieg!", UiTheme.F_TITLE, 44, Color(0.72, 0.78, 0.95) if defeat else UiTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if defeat:
		var sad := _label("Die Gruppe ist gefallen. Ein neuer Versuch auf frischem Schlachtfeld wartet. Die Statistik zeigt, was schiefging.", UiTheme.F_BODY, 22, Color(0.82, 0.82, 0.9))
		sad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sad.custom_minimum_size = Vector2(500, 0)
		col.add_child(sad)
	else:
		col.add_child(_label("Beute", UiTheme.F_HEAD, 22, UiTheme.GOLD))
		var lines := _loot_lines()
		if lines.is_empty():
			col.add_child(_label("Nichts gefunden.", UiTheme.F_BODY, 22, Color(0.8, 0.78, 0.72)))
		for l in lines:
			col.add_child(_label(l, UiTheme.F_BODY, 24, UiTheme.CREAM))
	var objs: Array = results.get("objectives", [])
	if not objs.is_empty():
		col.add_child(_label("Bonusziele", UiTheme.F_HEAD, 22, UiTheme.GOLD))
		for o: Dictionary in objs:
			var rew := _reward_text(o["reward"])
			var txt := "%s: %s%s" % [("erfüllt" if o["done"] else "verpasst"), o["text"], ("  (" + rew + ")") if o["done"] and rew != "" else ""]
			col.add_child(_label(txt, UiTheme.F_BODY, 22, Color(0.65, 1.0, 0.65) if o["done"] else Color(0.75, 0.6, 0.6)))
	var b := Button.new()
	b.text = "Noch einmal versuchen" if defeat else "Weiter"
	b.custom_minimum_size = Vector2(260 if defeat else 180, 38)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	col.add_child(b)


## Rechte Seite: Statistik der Gruppe (Tabelle je Figur) und Auszeichnungen.
func _build_stats() -> void:
	var st: Dictionary = results.get("stats", {})
	var rows: Array = st.get("rows", [])
	if rows.is_empty():
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(30, 22, 30, 22), 0.94))
	panel.custom_minimum_size = Vector2(580, 0)
	panel.position = Vector2(650, 90)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	panel.add_child(col)
	col.add_child(_label("Statistik – Runde %d" % int(results.get("turns", 0)), UiTheme.F_HEAD, 24, Color(0.72, 0.78, 0.95) if results.get("defeat", false) else UiTheme.GOLD))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 3)
	col.add_child(grid)
	for h in ["", "Schaden", "Erlitten", "Geheilt", "Besiegt"]:
		var hl := _label(h, UiTheme.F_BODY, 17, Color(0.85, 0.8, 0.55), HORIZONTAL_ALIGNMENT_RIGHT if h != "" else HORIZONTAL_ALIGNMENT_LEFT)
		grid.add_child(hl)
	for r: Dictionary in rows:
		var nm := _label(("† " if not r["alive"] else "") + String(r["name"]), UiTheme.F_BODY, 19, UiTheme.CREAM if r["alive"] else Color(0.7, 0.55, 0.55))
		nm.custom_minimum_size = Vector2(190, 0)
		grid.add_child(nm)
		for k in ["dealt", "taken", "healed", "kills"]:
			grid.add_child(_label(str(int(r[k])), UiTheme.F_BODY, 19, UiTheme.CREAM, HORIZONTAL_ALIGNMENT_RIGHT))
	var awards: Array = st.get("awards", [])
	if not awards.is_empty():
		col.add_child(_label("Auszeichnungen", UiTheme.F_HEAD, 20, UiTheme.GOLD))
		for a: Dictionary in awards:
			var l := _label("%s: %s (%s)" % [a["title"], a["name"], a["text"]], UiTheme.F_BODY, 18, Color(0.9, 0.9, 0.75))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(520, 0)
			col.add_child(l)


func _label(text: String, font: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _reward_text(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(r.get("gold", 0)) > 0:
		parts.append("%d Gold" % int(r["gold"]))
	for id: String in r.get("items", {}):
		parts.append(Items.item_name(id))
	for id: String in r.get("materials", {}):
		parts.append(Items.item_name(id))
	return ", ".join(parts)


func _loot_lines() -> Array[String]:
	var out: Array[String] = []
	if int(results.get("gold", 0)) > 0:
		out.append("%d Gold" % int(results["gold"]))
	for id: String in results.get("items", {}):
		out.append("%s ×%d" % [Items.item_name(id), int(results["items"][id])])
	for id: String in results.get("materials", {}):
		out.append("%s ×%d" % [Items.item_name(id), int(results["materials"][id])])
	for id: String in results.get("equipment", []):
		out.append(Items.item_name(id))
	return out
