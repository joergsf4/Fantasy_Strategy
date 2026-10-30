class_name RewardScreen
extends Control
## Belohnungsbildschirm nach einem gewonnenen Kampf: Beute, Gold, Bonusziele. "Weiter" schliesst ihn.

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
	panel.position = Vector2(360, 110)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(_label("Sieg!", UiTheme.F_TITLE, 44, UiTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
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
	b.text = "Weiter"
	b.custom_minimum_size = Vector2(180, 38)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	col.add_child(b)


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
