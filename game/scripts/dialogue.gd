class_name Dialogue
extends Control
## Anime-Dialogszene: links ein Sprecher, rechts einer (gespiegelt), davor Textfeld mit Namensband.
## Der Hintergrund bleibt frei: dahinter liegt die (unscharfe) Spielkarte der Stage.

signal finished

const PORTRAIT_DIR := "res://assets/portraits/"
const DIM := Color(0.5, 0.5, 0.58)

var lines: Array = []
var names: Dictionary = {}
var _idx := -1
var _typing := false
var _left: TextureRect
var _right: TextureRect
var _name_label: Label
var _plate: PanelContainer
var _text: RichTextLabel
var _more: Control
var _tween: Tween


func setup(dialogue_lines: Array, unit_names: Dictionary) -> void:
	lines = dialogue_lines
	names = unit_names


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_left = _make_slot(Rect2(-30, 10, 640, 700), false)
	_right = _make_slot(Rect2(670, 10, 640, 700), true)

	var box := PanelContainer.new()
	box.position = Vector2(60, 548)
	box.size = Vector2(1160, 148)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(26, 18, 26, 14), 0.86))
	add_child(box)
	_text = RichTextLabel.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 26)
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_text)

	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_theme_stylebox_override("panel", UiTheme.soft_plate(Vector4(34, 6, 34, 8), 0.92))
	add_child(_plate)
	_name_label = Label.new()
	_name_label.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	_name_label.add_theme_font_size_override("font_size", 19)
	_name_label.add_theme_color_override("font_color", UiTheme.GOLD)
	_name_label.add_theme_constant_override("outline_size", 3)
	_plate.add_child(_name_label)

	_more = Control.new()
	_more.position = Vector2(1184, 668)
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_more.draw.connect(func() -> void:
		var c := UiTheme.GOLD
		_more.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(22, 0), Vector2(11, 14)]), Color(0.08, 0.05, 0.1))
		_more.draw_colored_polygon(PackedVector2Array([Vector2(3, 2), Vector2(19, 2), Vector2(11, 11)]), c))
	add_child(_more)
	_more.visible = false
	var pulse := create_tween().set_loops()
	pulse.tween_property(_more, "modulate:a", 0.25, 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_more, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_advance()


func _make_slot(r: Rect2, flip: bool) -> TextureRect:
	var t := TextureRect.new()
	t.position = r.position
	t.size = r.size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.flip_h = flip
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(t)
	return t


## expr = "lachend" / "wuetend" / "" -> nimmt <id>_<expr>.png, falls vorhanden, sonst das Normalbild.
func _set_portrait(slot: TextureRect, id: String, expr := "") -> void:
	if id == "":
		slot.texture = null
		return
	var path := PORTRAIT_DIR + id + ".png"
	if expr != "" and ResourceLoader.exists(PORTRAIT_DIR + id + "_" + expr + ".png"):
		path = PORTRAIT_DIR + id + "_" + expr + ".png"
	slot.texture = load(path)


func _advance() -> void:
	if _typing:
		_tween.kill()
		_text.visible_ratio = 1.0
		_typing = false
		_more.visible = true
		return
	_idx += 1
	if _idx >= lines.size():
		finished.emit()
		queue_free()
		return
	var l: Dictionary = lines[_idx]
	_set_portrait(_left, l.get("left", ""), l.get("left_expr", ""))
	_set_portrait(_right, l.get("right", ""), l.get("right_expr", ""))
	var speaker: String = l.get("speaker", "")
	var on_left: bool = speaker == l.get("left", "")
	_left.modulate = Color.WHITE if on_left else DIM
	_right.modulate = DIM if on_left else Color.WHITE
	_name_label.text = names.get(speaker, speaker)
	_plate.reset_size()
	_plate.size = _plate.get_combined_minimum_size()
	_plate.position = Vector2(84.0 if on_left else 1280.0 - 84.0 - _plate.size.x, 524.0)
	_text.text = l["text"]
	_text.visible_ratio = 0.0
	_more.visible = false
	_typing = true
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.3, _text.text.length() * 0.025))
	_tween.finished.connect(func() -> void:
		_typing = false
		_more.visible = true)


## Weiterschalten: Linksklick irgendwo im Bild, Enter, Leertaste. _input statt _unhandled_input, damit kein
## Bedienelement (z. B. Abdunklung, HUD) den Klick abfangen kann; der Dialog verbraucht die Eingabe selbst.
func _input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	if click or key or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
