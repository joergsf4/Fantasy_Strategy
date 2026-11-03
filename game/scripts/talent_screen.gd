class_name TalentScreen
extends Control
## Aufstiegs-Bildschirm: nach dem Statistikbildschirm (und vor einer Mission fuer neu hinzugekommene Helden), sobald ein Talentpunkt frei ist.
## Zeigt nur die uebergebenen Helden; die Musik laeuft weiter (Main).

signal closed

var party: Party
var unit_defs: Dictionary
var heroes: Array = []


func setup(p: Party, defs: Dictionary, hero_ids: Array) -> void:
	party = p
	unit_defs = defs
	heroes = hero_ids


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(28, 18, 28, 18), 0.95))
	panel.position = Vector2(110, 60)
	panel.custom_minimum_size = Vector2(1060, 560)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Stufe %d erreicht!" % party.level()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var sub := Label.new()
	sub.text = "Talentpunkte verteilen (nur für Helden, die mitkämpfen)"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiTheme.font(UiTheme.F_BODY))
	sub.add_theme_font_size_override("font_size", 19)
	sub.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	col.add_child(sub)
	var tp := TalentPanel.new()
	tp.setup(party, unit_defs, heroes)
	tp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(tp)
	var go := Button.new()
	go.text = "Fertig"
	go.custom_minimum_size = Vector2(220, 40)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "disabled"]:
		go.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	go.pressed.connect(func() -> void:
		for id: String in heroes:
			party.mark_prompted(id)
		closed.emit()
		queue_free())
	col.add_child(go)
