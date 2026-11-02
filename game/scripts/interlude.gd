class_name Interlude
extends Control
## Reisebild zwischen zwei Abschnitten: ein Standbild mit langsamem Zoom und Schwenk (Ken Burns), Titelkarte
## ("Kapitel 2" und Titel), Ein- und Ausblenden von Schwarz. Klick oder Leertaste ueberspringt.

signal finished

var image_path := "res://assets/ui/reise_schiff.jpg"
var kicker := ""
var title := ""
var duration := 8.0
var zoom_to := 1.16
var pan := Vector2(-40, -14)       # Verschiebung in Pixeln waehrend des Zooms
var _pic: TextureRect
var _black: ColorRect
var _done := false
var _age := 0.0


func setup(data: Dictionary) -> void:
	image_path = data.get("image", image_path)
	kicker = data.get("kicker", "")
	title = data.get("title", "")
	duration = float(data.get("duration", duration))
	zoom_to = float(data.get("zoom", zoom_to))
	if data.has("pan"):
		pan = Vector2(data["pan"][0], data["pan"][1])


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_pic = TextureRect.new()
	_pic.texture = load(image_path)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_pic.position = Vector2.ZERO
	_pic.size = Vector2(1280, 720)
	_pic.pivot_offset = Vector2(640, 360)
	add_child(_pic)
	var box := VBoxContainer.new()
	box.position = Vector2(0, 560)
	box.size = Vector2(1280, 130)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	add_child(box)
	box.add_child(_label(kicker, 34, UiTheme.GOLD))
	box.add_child(_label(title, _fit_size(title, 58, 1100.0), Color(1.0, 0.97, 0.85)))
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 0.0, 1.2).from(1.0)
	var kb := create_tween().set_parallel(true)
	kb.tween_property(_pic, "scale", Vector2(zoom_to, zoom_to), duration).from(Vector2.ONE).set_trans(Tween.TRANS_SINE)
	kb.tween_property(_pic, "position", pan, duration).from(Vector2.ZERO).set_trans(Tween.TRANS_SINE)
	var tt := create_tween()
	tt.tween_interval(2.0)
	tt.tween_property(box, "modulate:a", 1.0, 1.0)
	tt.tween_interval(duration - 5.8)
	tt.tween_property(box, "modulate:a", 0.0, 0.8)
	var out := create_tween()
	out.tween_interval(duration - 1.2)
	out.tween_property(_black, "modulate:a", 1.0, 1.2)
	out.tween_callback(_finish)


func _process(delta: float) -> void:
	_age += delta


func _unhandled_input(event: InputEvent) -> void:
	if _age < 0.6:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	return l


func _fit_size(text: String, max_size: int, max_width: float) -> int:
	var font := UiTheme.font(UiTheme.F_TITLE)
	var size: int = max_size
	while size > 24 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 24.0 > max_width:
		size -= 2
	return size
