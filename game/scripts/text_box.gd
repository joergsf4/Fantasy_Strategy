class_name TextBox
extends PanelContainer
## Kleine Textplakette, die sich bei leerem Text ausblendet. Verhaelt sich wie ein Label (`text`).

var text := "":
	set(v):
		text = v
		if _label != null:
			_label.text = v
		visible = v != ""
var _label: RichTextLabel


func _init(font_size := 20, centered := false, plate := false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if plate:
		add_theme_stylebox_override("panel", UiTheme.soft("panel_small_s.png", Vector4(9, 4, 9, 5), 0.78))
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("normal_font_size", font_size)
	_label.add_theme_color_override("default_color", Color(0.93, 0.9, 0.82, 0.95))
	if centered:
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	visible = false
